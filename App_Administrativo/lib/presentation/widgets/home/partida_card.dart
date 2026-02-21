import 'package:flutter/material.dart';
import '../../../models/partida_model.dart';

class PartidaCard extends StatelessWidget {
  final Partida partida;
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
            margin: const EdgeInsets.only(right: 16, bottom: 18), // Pequena margem para sombra não cortar
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding vertical reduzido
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3A68F), Color(0xFFF85C39)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF85C39).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
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
                      fontSize: 9, // Reduzido ligeiramente
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const Spacer(), // Distribui o espaço dinamicamente
                
                // Área dos Times e Placar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTeamInfo(
                      partida.equipeA?.atletica?.nome ?? "Time A",
                      partida.equipeA?.atletica?.escudoUrl,
                    ),

                    // Placar Central
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${partida.placarA} - ${partida.placarB}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28, // Reduzido de 32 para evitar overflow
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Bebas Neue',
                          ),
                        ),
                        const Text(
                          "VS",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    _buildTeamInfo(
                      partida.equipeB?.atletica?.nome ?? "Time B",
                      partida.equipeB?.atletica?.escudoUrl,
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInfo(String nome, String? logoUrl) {
    return SizedBox(
      width: 75,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20, // Reduzido de 24 para 20
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
            child: logoUrl == null
                ? Text(
                    nome[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 4), // Reduzido de 8 para 4
          Text(
            nome,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11, // Reduzido de 12 para 11
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}