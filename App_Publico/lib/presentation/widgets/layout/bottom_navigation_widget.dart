import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatefulWidget {
  final String currentRoute;

  const BottomNavigationWidget({
    super.key,
    required this.currentRoute,
  });

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  bool _menuAdicionarAberto = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Overlay Escuro quando o menu está aberto
        if (_menuAdicionarAberto)
          GestureDetector(
            onTap: () => setState(() => _menuAdicionarAberto = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.4),
            ),
          ),

        // Barra de Navegação
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: widget.currentRoute != '/home' 
                  ? () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false)
                  : null,
              child: Icon(
                Icons.home_filled,
                color: widget.currentRoute == '/home' ? const Color(0xFFF85C39) : Colors.white,
                size: 28,
              ),
            ),
           
            
            GestureDetector(
              onTap: widget.currentRoute != '/modalidades'
                  ? () => Navigator.pushNamedAndRemoveUntil(context, '/modalidades', (route) => false)
                  : null,
              child: Icon(
                Icons.emoji_events,
                color: widget.currentRoute == '/modalidades' ? const Color(0xFFF85C39) : Colors.white,
                size: 28,
              ),
            ),
            GestureDetector(
              onTap: widget.currentRoute != '/configuracoes'
                  ? () => Navigator.pushNamedAndRemoveUntil(context, '/configuracoes', (route) => false)
                  : null,
              child: Icon(
                Icons.settings,
                color: widget.currentRoute == '/configuracoes' ? const Color(0xFFF85C39) : Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}