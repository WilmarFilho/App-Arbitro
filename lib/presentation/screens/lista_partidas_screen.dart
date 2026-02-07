import 'package:flutter/material.dart';
import '../../data/models/partida_model.dart';
import '../../data/models/sumula_model.dart';

class ListaPartidasScreen extends StatelessWidget {
  const ListaPartidasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock de dados (Simulando o que viria do Spring Boot)
    final listaPartidas = [
      Partida(
        id: '101',
        nomeTimeA: 'Computação',
        nomeTimeB: 'Medicina',
        atletasTimeA: ['João', 'Carlos', 'Beto'],
        atletasTimeB: ['Marcos', 'Zé', 'Luiz'],
        dataHora: DateTime.now(),
        sumula: Sumula(id: 's1'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Jogos do Dia')),
      body: ListView.builder(
        itemCount: listaPartidas.length,
        itemBuilder: (context, index) {
          final partida = listaPartidas[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text('${partida.nomeTimeA} x ${partida.nomeTimeB}'),
              subtitle: Text('Status: ${partida.sumula.status.name}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Aqui navegaremos para a tela de Detalhes/Arbitragem
                _abrirPartida(context, partida);
              },
            ),
          );
        },
      ),
    );
  }

  void _abrirPartida(BuildContext context, Partida partida) {
    // Lógica de navegação será inserida aqui
    print('Abrindo partida: ${partida.id}');
  }
}