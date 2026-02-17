import 'package:flutter/material.dart';

class JogoDetalhesScreen extends StatelessWidget {
  final String timeA;
  final String timeB;
  final String placarA;
  final String placarB;
  final String status; // "AO VIVO", "40:00", "FINALIZADO"

  const JogoDetalhesScreen({
    super.key,
    required this.timeA,
    required this.timeB,
    this.placarA = "0",
    this.placarB = "0",
    this.status = "AO VIVO",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("DETALHES DO JOGO", style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 24)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF85C39),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildScoreHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _buildTimeline(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF85C39),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTeamBadge(timeA, Colors.white),
          Column(
            children: [
              Text(
                "$placarA - $placarB",
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          _buildTeamBadge(timeB, Colors.white),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String nome, Color cor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(nome[0], style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        Text(nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTimeline() {
    // Mock de eventos para visualização
    final eventos = [
      {'min': "38'", 'tipo': 'GOL', 'desc': 'Gol de Engenharia (Camisa 10)', 'icon': Icons.sports_soccer, 'color': Colors.green},
      {'min': "30'", 'tipo': 'CARTÃO', 'desc': 'Cartão Amarelo para Direito', 'icon': Icons.style, 'color': Colors.amber},
      {'min': "20'", 'tipo': 'SUB', 'desc': 'Substituição em Engenharia', 'icon': Icons.swap_horiz, 'color': Colors.blue},
      {'min': "05'", 'tipo': 'GOL', 'desc': 'Gol de Direito (Camisa 7)', 'icon': Icons.sports_soccer, 'color': Colors.green},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(25, 25, 25, 10),
          child: Text(
            "LINHA DO TEMPO",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final ev = eventos[index];
              return IntrinsicHeight(
                child: Row(
                  children: [
                    // Linha lateral da timeline
                    Column(
                      children: [
                        Container(
                          width: 2,
                          height: 20,
                          color: index == 0 ? Colors.transparent : Colors.grey[300],
                        ),
                        Icon(ev['icon'] as IconData, size: 20, color: ev['color'] as Color),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: index == eventos.length - 1 ? Colors.transparent : Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Conteúdo do Evento
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Text(ev['min'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF85C39))),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(ev['desc'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}