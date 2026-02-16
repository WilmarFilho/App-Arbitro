import 'package:flutter/material.dart';
import '../../screens/game/partida_screen.dart';

/// Widget do cronômetro da partida com controles
class GameTimerCard extends StatelessWidget {
  final int segundos;
  final bool rodando;
  final bool partidaJaIniciou;
  final PeriodoPartida periodoAtual;
  final bool emPausaTecnica;
  final String timeEmPausaTecnica;
  final int segundosPausaTecnica;
  final int segundosPausa;
  final int tempoProrrogacao;
  final bool temProrrogacao;
  final VoidCallback onToggleCronometro;
  final VoidCallback? onFinalizarPrimeiroTempo;
  final VoidCallback? onFinalizarSegundoTempo;
  final VoidCallback? onAbrirModalProrrogacao;

  const GameTimerCard({
    super.key,
    required this.segundos,
    required this.rodando,
    required this.partidaJaIniciou,
    required this.periodoAtual,
    required this.emPausaTecnica,
    required this.timeEmPausaTecnica,
    required this.segundosPausaTecnica,
    required this.segundosPausa,
    required this.tempoProrrogacao,
    required this.temProrrogacao,
    required this.onToggleCronometro,
    this.onFinalizarPrimeiroTempo,
    this.onFinalizarSegundoTempo,
    this.onAbrirModalProrrogacao,
  });

  String _formatarTempo(int totalSegundos) {
    int min = totalSegundos ~/ 60;
    int seg = totalSegundos % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  Widget _formatarTempoPausa() {
    int min = segundosPausa ~/ 60;
    int seg = segundosPausa % 60;
    return Text(
      '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} (Pausa em andamento)',
      style: TextStyle(
        color: rodando ? Colors.white60 : Colors.orange,
        fontSize: 10,
        fontWeight: rodando ? FontWeight.normal : FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (periodoAtual == PeriodoPartida.finalizada) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.sports_soccer, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text(
                'PARTIDA ENCERRADA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onToggleCronometro,
                icon: Icon(
                  rodando ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatarTempo(segundos),
                  style: const TextStyle(
                    color: Color(0xFFD4FFD4),
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (periodoAtual == PeriodoPartida.prorrogacao)
                  Text(
                    'PRORROGAÇÃO (${tempoProrrogacao ~/ 60}min)',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (temProrrogacao &&
                    periodoAtual != PeriodoPartida.intervalo)
                  Text(
                    'Prorrogação: ${tempoProrrogacao ~/ 60}min configurada',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (!rodando && partidaJaIniciou)
                  emPausaTecnica
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PAUSA TÉCNICA\n$timeEmPausaTecnica (${60 - segundosPausaTecnica}s)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : periodoAtual == PeriodoPartida.intervalo
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'INTERVALO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : _formatarTempoPausa()
                else
                  const SizedBox(height: 14),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (periodoAtual == PeriodoPartida.primeiroTempo &&
                  !emPausaTecnica) ...[
                _buildTimeButton(
                    "Fim 1º tempo", onFinalizarPrimeiroTempo ?? () {}),
                const SizedBox(height: 4),
              ],
              if (periodoAtual == PeriodoPartida.segundoTempo &&
                  !emPausaTecnica) ...[
                _buildTimeButton(
                    "Fim 2º tempo", onFinalizarSegundoTempo ?? () {}),
                const SizedBox(height: 4),
              ],
              if ((periodoAtual == PeriodoPartida.primeiroTempo ||
                      periodoAtual == PeriodoPartida.segundoTempo) &&
                  !emPausaTecnica)
                _buildTimeButton(
                  temProrrogacao
                      ? "Prr: ${tempoProrrogacao ~/ 60}min"
                      : "Dar Prorrogação",
                  onAbrirModalProrrogacao ?? () {},
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
