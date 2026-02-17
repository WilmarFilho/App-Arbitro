import 'package:flutter/material.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {

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
                'Configurações',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          // Barra de Navegação
          BottomNavigationWidget(currentRoute: '/configuracoes'),
        ],
      ),
    );
  }
}