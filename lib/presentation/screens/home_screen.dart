import 'package:flutter/material.dart';
import '../../data/models/partida_model.dart';
import '../../data/repositories/partida_repository.dart';
import 'confirma_partida_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PartidaRepository _repository = PartidaRepository();
  List<Partida> _partidas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final partidasCarregadas = await _repository.buscarPartidasDoDia();
      setState(() {
        _partidas = partidasCarregadas;
        _carregando = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // Definimos a cor de fundo como branco para que, ao scrollar, 
      // tudo o que estiver abaixo do gradiente seja branco puro.
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. O Fundo com Gradiente (apenas na metade superior)
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.7, -0.6),
                radius: 1.5,
                colors: [
                  Color(0xFFD1FFDA),
                  Color(0xFFB7FFEB),
                  Color(0xFFCBFFFB),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 2. O Conteúdo com Scroll
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeaderSection(),
                  _buildCardsSection(),
                  const SizedBox(height: 30),
                  _buildWhatDoYouWantSection(),
                  const SizedBox(height: 25),
                  
                  // O Container Branco que "estica"
                  _buildMainGamesSection(),
                ],
              ),
            ),
          ),

          // 3. Barra de Navegação Fixa
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Olá {Nome},', style: TextStyle(fontFamily: 'Poppins', fontSize: 24)),
              Text('Seja bem vindo!', style: TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF555555),
            child: Icon(Icons.person_outline, color: Colors.white, size: 30),
          )
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        physics: const BouncingScrollPhysics(),
        itemCount: _partidas.isEmpty ? 3 : _partidas.length,
        itemBuilder: (context, index) {
          final partida = _partidas.isNotEmpty ? _partidas[index] : null;
          return GestureDetector(
            onTap: partida != null ? () => _confirmarInicioPartida(context, partida) : null,
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3A68F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Futsal', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text('ID: ${partida?.id ?? '13123142'}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const Text('Data: 21/10/2026', style: TextStyle(color: Colors.white, fontSize: 14)),
                        const Text('Hora: 14:00', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: const Text('SEU JOGO', style: TextStyle(color: Color(0xFFF3A68F), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWhatDoYouWantSection() {
    return Column(
      children: [
        const Text('OQUE VOCÊ QUER VER?', style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 32)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildOptionButton(Icons.person, 'Jogos'),
            _buildOptionButton(Icons.person, 'Árbitros'),
            _buildOptionButton(Icons.person, 'Campeonatos'),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: const Color(0xFFF85C39),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
      ],
    );
  }

  Widget _buildMainGamesSection() {
    return Container(
      width: double.infinity,
      // A mágica está aqui: O container não tem altura fixa, 
      // ele ocupa o espaço necessário e a cor de fundo do Scaffold faz o resto.
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 120),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jogos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Ver Todos / Ver Meus', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          // Gerando itens de partidas reais ou dados de exemplo
          ...(_partidas.isNotEmpty 
            ? _partidas.map((partida) => _buildGameListItem(partida: partida)).toList()
            : List.generate(10, (index) => _buildGameListItem())),
        ],
      ),
    );
  }

  Widget _buildGameListItem({Partida? partida}) {
    return GestureDetector(
      onTap: partida != null ? () => _confirmarInicioPartida(context, partida) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(18)),
        child: Row(
        children: [
          const Icon(Icons.sports_basketball, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Futsal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(partida != null ? '${partida.nomeTimeA} x ${partida.nomeTimeB}' : 'Computaria Masculina', 
                     style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
              ],
            ),
          ),
          const Text('14/10/2026 14:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 25,
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
            const Icon(Icons.home_filled, color: Colors.white, size: 28),
            const Icon(Icons.search, color: Colors.white, size: 28),
            Transform.translate(
              offset: const Offset(0, -5),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.black, size: 32),
              ),
            ),
            const Icon(Icons.person, color: Colors.white, size: 28),
            const Icon(Icons.settings, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  void _confirmarInicioPartida(BuildContext context, Partida partida) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text('Iniciar Súmula?', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Deseja iniciar o cronômetro e o registro oficial para ${partida.nomeTimeA} x ${partida.nomeTimeB}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await _repository.iniciarPartida(partida);
                if (!mounted) return;
                Navigator.of(context).pop();
                _navegarParaSumula(context, partida);
              },
              child: const Text('CONFIRMAR'),
            ),
          ],
        );
      },
    );
  }

   void _navegarParaSumula(BuildContext context, Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConfirmaPartidaScreen(partida: partida)),
    ).then((_) => _carregarDadosIniciais());
  }
}