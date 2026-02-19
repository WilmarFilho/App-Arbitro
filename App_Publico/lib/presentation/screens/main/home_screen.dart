import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/presentation/widgets/home/partida_card.dart';
import '../../../models/partida_model.dart';
import '../../../services/partida_service.dart'; // Importe seu novo service
import '../game/partida_screen.dart';

import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/partida_list_item.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PartidaService _partidaService = PartidaService();
  
  List<Partida> _partidasDestaque = [];
  List<Partida> _historicoPartidas = [];
  bool _carregandoDados = true;
  bool _verMeus = false;

  late AnimationController _animationController;
  // Animações agora serão geradas dinamicamente com base no tamanho da lista
  late List<Animation<double>> _fadeAnimations = [];
  late List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _carregarDadosReais();
  }

  void _initializeAnimations(int count) {
    _fadeAnimations = List.generate(count, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.5),
            (index * 0.1 + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(count, (index) {
      return Tween<Offset>(begin: const Offset(0.3, 0.0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.5),
            (index * 0.1 + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosReais() async {
    if (!mounted) return;
    setState(() => _carregandoDados = true);
    _animationController.reset();

    try {
      // Busca dados em paralelo para maior rapidez
      final resultados = await Future.wait([
        _partidaService.listarPartidasDestaque(),
        _partidaService.listarHistoricoPartidas(),
      ]);

      if (mounted) {
        setState(() {
          _partidasDestaque = resultados[0];
          _historicoPartidas = resultados[1];
          _initializeAnimations(_partidasDestaque.length);
          _carregandoDados = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
      if (mounted) setState(() => _carregandoDados = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(heightFactor: 0.85),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _carregarDadosReais,
              color: const Color(0xFFF85C39),
              child: CustomScrollView( // Usando CustomScrollView para um scroll mais fluido
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  const SliverToBoxAdapter(child: HomeHeader()),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                      child: Text(
                        "PARTIDAS EM DESTAQUE",
                        style: TextStyle(
                          fontFamily: 'Bebas Neue',
                          fontSize: 22,
                          color: Color.fromARGB(255, 32, 32, 32),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildCardsSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 25)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildMainGamesSection(),
                  ),
                ],
              ),
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
    if (_carregandoDados) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_partidasDestaque.isEmpty) {
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text("Nenhuma partida ao vivo no momento", 
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        ),
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: _partidasDestaque.length,
        itemBuilder: (context, index) {
          final partida = _partidasDestaque[index];
          return PartidaCard(
            partida: partida,
            fadeAnimation: _fadeAnimations.length > index 
                ? _fadeAnimations[index] 
                : AlwaysStoppedAnimation(1.0),
            slideAnimation: _slideAnimations.length > index 
                ? _slideAnimations[index] 
                : AlwaysStoppedAnimation(Offset.zero),
            onTap: () => _navegarParaPartida(context, partida),
          );
        },
      ),
    );
  }

  Widget _buildMainGamesSection() {
    return Container(
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
                Text("HISTÓRICO", 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Bebas Neue')),
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
          if (_carregandoDados)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_historicoPartidas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text("Nenhuma partida finalizada recentemente."),
            )
          else
            ..._historicoPartidas.map((partida) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: PartidaListItem( // Widget para a lista vertical
                partida: partida,
                onTap: () => _navegarParaPartida(context, partida),
              ),
            )).toList(),
          const SizedBox(height: 100), // Espaço para o bottom nav
        ],
      ),
    );
  }

  void _navegarParaPartida(BuildContext context, Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JogoDetalhesScreen(
          partidaId: partida.id, // Passe o ID para carregar os eventos lá
          timeA: partida.equipeA?.nome ?? "Time A",
          timeB: partida.equipeB?.nome ?? "Time B",
          status: partida.status.toUpperCase(),
          placarA: partida.placarA.toString(),
          placarB: partida.placarB.toString(),
        ),
      ),
    );
  }
}


