import 'package:flutter/material.dart';

/// Widget de lista de eventos para o resumo da partida
class SummaryEventList extends StatelessWidget {
  final List<dynamic> eventos;

  const SummaryEventList({
    super.key,
    required this.eventos,
  });

  @override
  Widget build(BuildContext context) {
    // Se a lista estiver vazia, mostra um placeholder
    if (eventos.isEmpty) {
      return const Center(child: Text("Nenhum evento registrado."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        final ev = eventos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: _getIconForEvent(ev.tipo),
            title: Text(
              ev.descricao,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text("Tempo: ${ev.horario}"),
            trailing: CircleAvatar(radius: 4, backgroundColor: ev.corTime),
          ),
        );
      },
    );
  }

  // Helper para ícones dos eventos
  Widget _getIconForEvent(String tipo) {
    switch (tipo) {
      case 'Gol':
        return const Icon(Icons.sports_soccer, color: Colors.green);
      case 'Cartão Amarelo':
        return const Icon(Icons.style, color: Colors.amber);
      case 'Cartão Vermelho':
        return const Icon(Icons.style, color: Colors.red);
      default:
        return const Icon(Icons.info_outline, color: Colors.grey);
    }
  }
}
