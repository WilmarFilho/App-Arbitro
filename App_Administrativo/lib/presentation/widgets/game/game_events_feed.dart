import 'package:flutter/material.dart';
import '../../screens/game/partida_screen.dart';

/// Widget do feed horizontal de eventos da partida
class GameEventsFeed extends StatelessWidget {
  final List<EventoPartida> eventos;

  const GameEventsFeed({
    super.key,
    required this.eventos,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: eventos.isEmpty
          ? const Center(
              child: Text(
                "Aguardando lances...",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: eventos.length,
              itemBuilder: (context, index) => _buildEventItem(eventos[index]),
            ),
    );
  }

  Widget _buildEventItem(EventoPartida evento) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: evento.corTime, radius: 4),
          const SizedBox(width: 8),
          Text(
            "${evento.descricao} - ${evento.horario}",
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
