import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({
    super.key,
    this.userName = 'Wilmar',
  });

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá $userName,',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                ),
              ),
              const Text(
                'Seja bem vindo!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Botão de Logout
              GestureDetector(
                onTap: () => _logout(context),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFF555555),
                  child: Icon(Icons.logout, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Botão de Perfil
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/perfil'),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFF555555),
                  child: Icon(Icons.person_outline, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}