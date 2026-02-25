import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import '../../screens/game/partida_screen.dart';

/// Widget do campo de futsal com os jogadores posicionados
class GameField extends StatelessWidget {
  final List<Atleta> jogadoresA;
  final List<Atleta> jogadoresB;
  final Atleta? jogadorSelecionado;
  final void Function(Atleta?) onJogadorSelecionado;
  final void Function(Atleta) onJogadorDoubleTap;

  const GameField({
    super.key,
    required this.jogadoresA,
    required this.jogadoresB,
    required this.jogadorSelecionado,
    required this.onJogadorSelecionado,
    required this.onJogadorDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double campoWidth = constraints.maxWidth;
        const double campoHeight = 250;

        return Container(
          height: campoHeight,
          width: campoWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF8DBA94),
            borderRadius: BorderRadius.circular(15),
            // ignore: deprecated_member_use
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
          ),
          child: Stack(
            children: [
              // Linhas do campo
              Center(child: Container(width: 2, color: Colors.white54)),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 2),
                  ),
                ),
              ),
              // Renderiza todos os jogadores
              ...[
                ...jogadoresA,
                ...jogadoresB,
              ].map((jog) => _buildPlayerWidget(jog, campoWidth, campoHeight)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerWidget(Atleta jogador, double width, double height) {
    bool selecionado = jogadorSelecionado == jogador;

    return Positioned(
      left: jogador.posicao!.dx * width,
      top: jogador.posicao!.dy * height,
      child: GestureDetector(
        onTap: () {
          // Se o jogador já está selecionado, limpa a seleção
          // Caso contrário, seleciona o jogador
          onJogadorSelecionado(selecionado ? null : jogador);
        },
        onDoubleTap: () => onJogadorDoubleTap(jogador),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(selecionado ? 4 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selecionado
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: jogador.corTime,
                child: Text(
                  "${jogador.numero}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Text(
              jogador.nome.split(' ')[0],
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
