import 'package:flutter/material.dart';
import '../../screens/game/partida_screen.dart';

/// Widget do placar da partida mostrando os dois times e seus gols
class GameScoreboard extends StatelessWidget {
  final String timeA;
  final String timeB;
  final String? escudoA;
  final String? escudoB;
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
    required this.escudoA,
    required this.escudoB,
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
          Expanded(child: _buildTeamScore(timeA, golsA, true)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 2,
            height: 80,
            color: Colors.grey[200],
          ),
          Expanded(child: _buildTeamScore(timeB, golsB, false)),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String nome, int gols, bool isTimeA) {
    final bool podeUsarPausa =
        rodando &&
        podeUsarPausaTecnica(isTimeA) &&
        (periodoAtual == PeriodoPartida.primeiroTempo ||
            periodoAtual == PeriodoPartida.segundoTempo ||
            periodoAtual == PeriodoPartida.prorrogacao);

    final String logoUrl = (isTimeA ? escudoA : escudoB) ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nome,
          maxLines: 2,
          softWrap: true,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),

        // ✅ Trata escudo vazio: mostra inicial do time se não tiver URL
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
          child: logoUrl.isEmpty
              ? Text(
                  nome.isNotEmpty ? nome[0] : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),

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

        // 1. Botão de solicitar pausa
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
        // 2. Botão de finalizar pausa
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
        // 3. Indicador de pausa esgotada
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
        // 4. Espaçador
        else
          const SizedBox(height: 20),
      ],
    );
  }
}
