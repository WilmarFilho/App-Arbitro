import 'package:flutter/material.dart';
import 'presentation/screens/lista_partidas_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SGEU - Árbitro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
      ),
      // Aqui definimos que a tela inicial agora é a lista de jogos
      home: const ListaPartidasScreen(),
    );
  }
}