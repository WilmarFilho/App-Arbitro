import 'package:flutter/material.dart';
import '../../screens/game/partida_screen.dart';

/// Widget do placar da partida mostrando os dois times e seus gols
class GameScoreboard extends StatelessWidget {
  final String timeA;
  final String timeB;
  final int golsA;
  final int golsB;
  final PeriodoPartida periodoAtual;
  final bool emPausaTecnica;
  final bool rodando;
  final String timeEmPausaTecnica;
  final int segundosPausaTecnica;
  final bool Function(bool) podeUsarPausaTecnica;
  final void Function(bool) onPausaTecnicaIniciada;
  final VoidCallback onPausaTecnicaFinalizada;

  const GameScoreboard({
    super.key,
    required this.timeA,
    required this.timeB,
    required this.golsA,
    required this.golsB,
    required this.periodoAtual,
    required this.emPausaTecnica,
    required this.rodando,
    required this.timeEmPausaTecnica,
    required this.segundosPausaTecnica,
    required this.podeUsarPausaTecnica,
    required this.onPausaTecnicaIniciada,
    required this.onPausaTecnicaFinalizada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTeamScore(timeA, Icons.laptop, golsA, true),
          Container(width: 2, height: 80, color: Colors.grey[200]),
          _buildTeamScore(timeB, Icons.add_moderator, golsB, false),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String nome, IconData icon, int gols, bool isTimeA) {
    // AJUSTE: Adicionada a verificação 'rodando'
    bool podeUsarPausa =
        rodando &&
        podeUsarPausaTecnica(isTimeA) &&
        (periodoAtual == PeriodoPartida.primeiroTempo ||
            periodoAtual == PeriodoPartida.segundoTempo ||
            periodoAtual == PeriodoPartida.prorrogacao);

    return Column(
      children: [
        Text(
          nome,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon, size: 30),
        const SizedBox(height: 8),
        Text(
          gols.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF5733),
          ),
        ),
        const SizedBox(height: 8),

        // 1. Botão de solicitar pausa (Só aparece se rodando e tiver direito)
        if (podeUsarPausa && !emPausaTecnica)
          GestureDetector(
            onTap: () => onPausaTecnicaIniciada(isTimeA),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Pausa Técnica',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        // 2. Botão de finalizar pausa (Aparece se já estiver em pausa)
        else if (emPausaTecnica && timeEmPausaTecnica == nome)
          GestureDetector(
            onTap: onPausaTecnicaFinalizada,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Finalizar (${60 - segundosPausaTecnica}s)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        // 3. Indicador de Pausa Esgotada (Só aparece se o cronômetro estiver rodando ou
        // em período de jogo, mas o time já usou o seu direito)
        else if (!podeUsarPausa &&
            rodando &&
            (periodoAtual == PeriodoPartida.primeiroTempo ||
                periodoAtual == PeriodoPartida.segundoTempo ||
                periodoAtual == PeriodoPartida.prorrogacao))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pausa Usada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        // 4. Espaçador caso não cumpra nenhuma condição (Partida pausada ou intervalo)
        else
          const SizedBox(height: 20),
      ],
    );
  }
}
