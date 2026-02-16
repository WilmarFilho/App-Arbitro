import 'package:flutter/material.dart';
import '../../screens/game/partida_screen.dart';

/// Widget do painel de ações da partida (gols, cartões, substituições, etc)
class GameActionsPanel extends StatelessWidget {
  final JogadorFutsal? jogadorSelecionado;
  final PeriodoPartida periodoAtual;
  final void Function(String) onRegistrarEvento;

  const GameActionsPanel({
    super.key,
    required this.jogadorSelecionado,
    required this.periodoAtual,
    required this.onRegistrarEvento,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildActionButton(
            "Gol",
            const Color(0xFF00FFC2),
            Colors.black,
            onTap: () => onRegistrarEvento("Gol"),
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            "Substituição",
            Colors.white,
            Colors.black,
            onTap: () => onRegistrarEvento("Substituição"),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Cartões",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            "Falta",
            const Color(0xFFFF3D00),
            Colors.white,
            onTap: () => onRegistrarEvento("Falta"),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  "Cartão Amarelo",
                  Colors.yellow,
                  Colors.black,
                  onTap: () => onRegistrarEvento("Cartão Amarelo"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  "Cartão Vermelho",
                  const Color(0xFFD32F2F),
                  Colors.white,
                  onTap: () => onRegistrarEvento("Cartão Vermelho"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Saídas",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildExitButton(
                  "Tiro de saída",
                  onTap: () => onRegistrarEvento("Tiro de Saída"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildExitButton(
                  "Tiro livre direto",
                  onTap: () => onRegistrarEvento("Tiro Livre Direto"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildExitButton(
                  "Tiro livre indireto",
                  onTap: () => onRegistrarEvento("Tiro Livre Indireto"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildExitButton(
                  "Tiro Lateral",
                  onTap: () => onRegistrarEvento("Tiro Lateral"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildExitButton(
                  "Tiro de Canto",
                  onTap: () => onRegistrarEvento("Tiro de Canto"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildExitButton(
                  "Arremesso de Meta",
                  onTap: () => onRegistrarEvento("Arremesso de Meta"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color fundo,
    Color texto, {
    VoidCallback? onTap,
  }) {
    bool isEnabled = jogadorSelecionado != null &&
        periodoAtual != PeriodoPartida.naoIniciada;
    Color backgroundColor = isEnabled ? fundo : Colors.grey[400]!;
    Color textColor = isEnabled ? texto : Colors.grey[600]!;

    return GestureDetector(
      onTap: isEnabled && onTap != null ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: isEnabled
              ? null
              : Border.all(color: Colors.grey[300]!, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isEnabled) Icon(Icons.person_off, color: textColor, size: 16),
            if (!isEnabled) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isEnabled ? 14 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExitButton(String label, {VoidCallback? onTap}) {
    bool isEnabled = jogadorSelecionado != null &&
        periodoAtual != PeriodoPartida.naoIniciada;
    Color backgroundColor = isEnabled ? Colors.white : Colors.grey[300]!;
    Color textColor = isEnabled ? Colors.black : Colors.grey[600]!;

    return GestureDetector(
      onTap: isEnabled && onTap != null ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? Colors.grey[400]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
