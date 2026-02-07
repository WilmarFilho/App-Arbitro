import 'package:flutter/material.dart';
import '../../data/models/partida_model.dart';
import '../../data/repositories/partida_repository.dart'; // Importe o repositório
import 'sumula_screen.dart';

class ListaPartidasScreen extends StatefulWidget {
  const ListaPartidasScreen({super.key});

  @override
  State<ListaPartidasScreen> createState() => _ListaPartidasScreenState();
}

class _ListaPartidasScreenState extends State<ListaPartidasScreen> {
  final PartidaRepository _repository = PartidaRepository();
  List<Partida> _partidas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  // Chame a função inicial que popula o banco e retorna a lista
  Future<void> _carregarDadosIniciais() async {
    try {
      final partidasCarregadas = await _repository.buscarPartidasDoDia();
      setState(() {
        _partidas = partidasCarregadas;
        _carregando = false;
      });
    } catch (e) {
      print("Erro ao carregar dados: $e");
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogos do Dia'),
        actions: [
          // Botão para recarregar manualmente se necessário
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _carregando = true);
              _carregarDadosIniciais();
            },
          )
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _partidas.isEmpty
              ? const Center(child: Text("Nenhuma partida encontrada."))
              : ListView.builder(
                  itemCount: _partidas.length,
                  itemBuilder: (context, index) {
                    final partida = _partidas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text('${partida.nomeTimeA} x ${partida.nomeTimeB}'),
                        subtitle: Text('ID: ${partida.id} | Status: ${partida.sumula.status.name}'),
                        trailing: const Icon(Icons.play_circle_outline, color: Colors.blue),
                        onTap: () => _abrirPartida(context, partida),
                      ),
                    );
                  },
                ),
    );
  }

  void _abrirPartida(BuildContext context, Partida partida) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Iniciar Súmula?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Você iniciará a partida entre ${partida.nomeTimeA} e ${partida.nomeTimeB}.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text('• O registro será salvo no banco local.'),
              const Text('• O cronômetro será ativado.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Importante: Notifica o repositório que a partida iniciou
                await _repository.iniciarPartida(partida);
                
                if (!mounted) return;
                Navigator.of(context).pop(); 
                _navegarParaSumula(context, partida);
              },
              child: const Text('CONFIRMAR E INICIAR'),
            ),
          ],
        );
      },
    );
  }

  void _navegarParaSumula(BuildContext context, Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SumulaScreen(partida: partida)),
    ).then((_) => _carregarDadosIniciais()); // Atualiza a lista ao voltar
  }
}