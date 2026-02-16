import 'package:flutter/material.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/game/summary_header.dart';
import '../../widgets/game/summary_score_card.dart';
import '../../widgets/game/summary_event_list.dart';
import '../../widgets/game/summary_action_buttons.dart';

class MatchSummaryScreen extends StatelessWidget {
  final String timeA;
  final String timeB;
  final int golsA;
  final int golsB;
  // Aqui passamos a lista de eventos capturados na tela anterior
  final List<dynamic> eventos;

  const MatchSummaryScreen({
    super.key,
    required this.timeA,
    required this.timeB,
    required this.golsA,
    required this.golsB,
    required this.eventos,
  });

  @override
  Widget build(BuildContext context) {
    // Bloqueia o gesto de voltar do Android/iOS
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Fundo com Gradiente
            const GradientBackground(),
            // Conteúdo Principal
            SafeArea(
              child: Column(
                children: [
                  const SummaryHeader(),
                  SummaryScoreCard(
                    timeA: timeA,
                    timeB: timeB,
                    golsA: golsA,
                    golsB: golsB,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "RESUMO DOS EVENTOS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SummaryEventList(eventos: eventos),
                  ),
                  SummaryActionButtons(
                    onPdfPressed: () {
                      // Lógica para abrir PDF futuramente
                    },
                    onHomePressed: () {
                      // Volta para a tela inicial (home) limpando a pilha de navegação
                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
