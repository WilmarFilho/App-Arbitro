import 'package:flutter/material.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';

class ArbitrosScreen extends StatefulWidget {
  const ArbitrosScreen({super.key});

  @override
  State<ArbitrosScreen> createState() => _ArbitrosScreenState();
}

class _ArbitrosScreenState extends State<ArbitrosScreen> {

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          // Fundo com Gradiente
          GradientBackground(),

          // Conteúdo Principal
          SafeArea(
            child: Center(
              child: Text(
                'Árbitros',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          // Barra de Navegação
          BottomNavigationWidget(currentRoute: '/arbitros'),
        ],
      ),
    );
  }
}