import 'package:flutter/material.dart';
import '../../screens/game/partida_screen.dart';

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
  
  // Novos campos para Acréscimo
  final int tempoAcrescimo;
  final bool temAcrescimo;

  final VoidCallback onToggleCronometro;
  final VoidCallback? onFinalizarPrimeiroTempo;
  final VoidCallback? onFinalizarSegundoTempo;
  final VoidCallback? onAbrirModalProrrogacao;
  final VoidCallback? onAbrirModalAcrescimo; // Novo callback

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
    required this.tempoAcrescimo, // Adicionado
    required this.temAcrescimo,    // Adicionado
    required this.onToggleCronometro,
    this.onFinalizarPrimeiroTempo,
    this.onFinalizarSegundoTempo,
    this.onAbrirModalProrrogacao,
    this.onAbrirModalAcrescimo,   // Adicionado
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
        children: [
          // Coluna do Play/Pause
          IconButton(
            onPressed: onToggleCronometro,
            icon: Icon(
              rodando ? Icons.pause_circle : Icons.play_circle,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          // Coluna Central (Cronômetro e Status)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatarTempo(segundos),
                  style: const TextStyle(
                    color: Color(0xFFD4FFD4),
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Feedback visual de Acréscimo
                if (temAcrescimo && periodoAtual != PeriodoPartida.intervalo)
                   Text(
                    '+${tempoAcrescimo ~/ 60} MIN ACRÉSCIMO',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                // Feedback visual de Prorrogação
                if (periodoAtual == PeriodoPartida.prorrogacao)
                  const Text('EM PRORROGAÇÃO', style: TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold))
                else if (temProrrogacao && periodoAtual == PeriodoPartida.segundoTempo)
                  Text('PRORROGAÇÃO CONFIGURADA (${tempoProrrogacao ~/ 60}min)', 
                       style: const TextStyle(color: Colors.orange, fontSize: 10)),
                
                // ... (Pausas técnicas e intervalo permanecem iguais)
              ],
            ),
          ),

          // Coluna de Ações (Botões à direita)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lógica para 1º Tempo
              if (periodoAtual == PeriodoPartida.primeiroTempo && !emPausaTecnica) ...[
                _buildTimeButton("Fim 1º tempo", onFinalizarPrimeiroTempo ?? () {}),
                const SizedBox(height: 4),
                _buildTimeButton(
                  temAcrescimo ? "Acr: ${tempoAcrescimo ~/ 60}min" : "Dar Acréscimo", 
                  onAbrirModalAcrescimo ?? () {}
                ),
              ],

              // Lógica para 2º Tempo
              if (periodoAtual == PeriodoPartida.segundoTempo && !emPausaTecnica) ...[
                _buildTimeButton("Fim 2º tempo", onFinalizarSegundoTempo ?? () {}),
                const SizedBox(height: 4),
                _buildTimeButton(
                  temAcrescimo ? "Acr: ${tempoAcrescimo ~/ 60}min" : "Dar Acréscimo", 
                  onAbrirModalAcrescimo ?? () {}
                ),
                const SizedBox(height: 4),
                // PRORROGAÇÃO: Só aparece no 2º tempo conforme solicitado
                _buildTimeButton(
                  temProrrogacao ? "Prr: ${tempoProrrogacao ~/ 60}min" : "Dar Prorrogação",
                  onAbrirModalProrrogacao ?? () {},
                ),
              ],
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
