import 'package:flutter/material.dart';
import '../../../models/partida_model.dart';

class PartidaCard extends StatelessWidget {
  final Partida partida; // Agora é obrigatório para exibir os dados reais
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback? onTap;

  const PartidaCard({
    super.key,
    required this.partida,
    required this.fadeAnimation,
    required this.slideAnimation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Usando a cor que você definiu, mas com um leve gradiente para dar profundidade
              gradient: const LinearGradient(
                colors: [Color(0xFFF3A68F), Color(0xFFF85C39)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF85C39).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge de Status (AO VIVO ou AGENDADO)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    partida.status == 'em_andamento' ? '● AO VIVO' : 'DESTAQUE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                
                // Área dos Times e Placar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time A
                    _buildTeamInfo(
                      partida.equipeA?.atletica?.nome ?? "Time A",
                      partida.equipeA?.atletica?.escudoUrl,
                    ),

                    // Placar Central
                    Column(
                      children: [
                        Text(
                          "${partida.placarA} - ${partida.placarB}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Bebas Neue', // Usando a fonte do seu cabeçalho
                          ),
                        ),
                        const Text(
                          "VS",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Time B
                    _buildTeamInfo(
                      partida.equipeB?.atletica?.nome ?? "Time B",
                      partida.equipeB?.atletica?.escudoUrl,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para montar a coluna de cada time dentro do card
  Widget _buildTeamInfo(String nome, String? logoUrl) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
            child: logoUrl == null
                ? Text(
                    nome[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            nome,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}