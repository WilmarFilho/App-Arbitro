import 'package:flutter/material.dart';
// 1. Importe o model centralizado (ajuste o caminho se necessário)
import '../../../models/partida_model.dart'; 
// 2. Certifique-se de que este import aponta para o arquivo de detalhes que criamos
import '../game/partida_screen.dart'; 

import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/partida_card.dart';
import '../../widgets/home/option_button.dart';
import '../../widgets/home/mock_list_item.dart';

// --- CLASSE PARTIDA REMOVIDA DAQUI ---
// Ela agora é lida do import '../../../models/partida_model.dart'

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Partida> _partidas = [];
  bool _carregandoDados = false;
  String _abaSelecionada = 'Jogos';
  bool _verMeus = false;

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _initializeAnimations();
    _carregarDadosSimulados();
  }

  void _initializeAnimations() {
    _fadeAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.2, (index * 0.2) + 0.8, curve: Curves.easeOutCubic),
        ),
      );
    });

    _slideAnimations = List.generate(3, (index) {
      return Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.2, (index * 0.2) + 0.8, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosSimulados() async {
    setState(() => _carregandoDados = true);
    await Future.delayed(const Duration(milliseconds: 800));

    // Usando o construtor do seu Partida centralizado
    _partidas = [
      Partida(id: '1', nomeTimeA: 'Engenharia', nomeTimeB: 'Direito', status: 'AO VIVO'),
      Partida(id: '2', nomeTimeA: 'Medicina', nomeTimeB: 'Economia', status: '14:00'),
      Partida(id: '3', nomeTimeA: 'Artes', nomeTimeB: 'Computação', status: 'FINALIZADO'),
    ];

    if (mounted) {
      setState(() => _carregandoDados = false);
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(heightFactor: 0.85),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const HomeHeader(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  child: Text(
                    "PARTIDAS EM DESTAQUE",
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: 20,
                      color: Color.fromARGB(255, 32, 32, 32),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildCardsSection(),
                const SizedBox(height: 25),
                Expanded(child: _buildMainGamesSection()),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationWidget(currentRoute: '/home'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    return SizedBox(
      height: 160,
      child: _carregandoDados
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              physics: const BouncingScrollPhysics(),
              itemCount: _partidas.length,
              itemBuilder: (context, index) {
                final partida = _partidas[index];
                return PartidaCard(
                  partida: partida,
                  fadeAnimation: _fadeAnimations[index.clamp(0, 2)],
                  slideAnimation: _slideAnimations[index.clamp(0, 2)],
                  onTap: () => _navegarParaPartida(context, partida),
                );
              },
            ),
    );
  }

  Widget _buildMainGamesSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_abaSelecionada.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _verMeus = !_verMeus),
                  child: Text(
                    _verMeus ? 'Ver Tudo' : 'Meus Favoritos',
                    style: TextStyle(
                      color: _verMeus ? const Color(0xFFF85C39) : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
              itemCount: 10,
              itemBuilder: (context, index) => MockListItem(sectionType: _abaSelecionada),
            ),
          ),
        ],
      ),
    );
  }

  void _navegarParaPartida(BuildContext context, Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JogoDetalhesScreen(
          timeA: partida.nomeTimeA,
          timeB: partida.nomeTimeB,
          status: partida.status,
          // Se seu model centralizado tiver placar, use partida.placarA
          placarA: "0", 
          placarB: "0",
        ),
      ),
    );
  }
}