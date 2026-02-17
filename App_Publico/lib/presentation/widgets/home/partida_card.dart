import 'package:flutter/material.dart';
// Certifique-se de que o arquivo abaixo contenha a classe Partida
import '../../../models/partida_model.dart'; 

class PartidaCard extends StatelessWidget {
  // O Dart agora reconhecerá que este Partida vem do import acima
  final Partida? partida;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback? onTap;

  const PartidaCard({
    super.key,
    this.partida,
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
            width: 260,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
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
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'FUTSAL',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamInitial(partida?.nomeTimeA ?? "A"),
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildTeamInitial(partida?.nomeTimeB ?? "B"),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${partida?.nomeTimeA ?? 'Time A'} x ${partida?.nomeTimeB ?? 'Time B'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInitial(String nome) {
    // Tratamento simples caso o nome chegue vazio
    String inicial = nome.isNotEmpty ? nome[0].toUpperCase() : "?";
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: Text(
        inicial,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}