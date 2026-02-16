import 'package:flutter/material.dart';
import 'package:kyarem_eventos/presentation/screens/game/partida_screen.dart';
import '../../../data/models/partida_model.dart';
import '../../../data/repositories/partida_repository.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/partida_card.dart';
import '../../widgets/home/option_button.dart';
import '../../widgets/home/mock_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PartidaRepository _repository = PartidaRepository();
  List<Partida> _partidas = [];
  bool _carregandoDados = false;
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  String _abaSelecionada = 'Jogos';
  bool _verMeus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _initializeAnimations();
    _carregarDadosIniciais();
  }

  void _initializeAnimations() {
    _fadeAnimations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.2,
          (index * 0.2) + 0.8,
          curve: Curves.easeOutCubic,
        ),
      ));
    });

    _slideAnimations = List.generate(3, (index) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.2,
          (index * 0.2) + 0.8,
          curve: Curves.easeOutCubic,
        ),
      ));
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    if (_carregandoDados) return; // Evita múltiplas chamadas
    
    setState(() => _carregandoDados = true);
    
    try {
      final partidasCarregadas = await _repository.buscarPartidasDoDia();
      setState(() {
        _partidas = partidasCarregadas;
        _carregandoDados = false;
      });
      
      // Inicia a animação após carregar os dados
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
      setState(() => _carregandoDados = false);
      // Anima mesmo com erro para mostrar cards mockados
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fundo com Gradiente
          const GradientBackground(),

          // 2. Estrutura Principal
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const HomeHeader(),
                _buildCardsSection(),
                const SizedBox(height: 20),
                _buildWhatDoYouWantSection(),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, 10),
                    child: _buildMainGamesSection(),
                  ),
                ),
              ],
            ),
          ),

          // 3. Barra de Navegação
          const BottomNavigationWidget(currentRoute: '/home'),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    return SizedBox(
      height: 130,
      child: _carregandoDados 
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF85C39)),
            ),
          )
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            physics: const BouncingScrollPhysics(),
            itemCount: _partidas.isEmpty ? 3 : _partidas.length,
            itemBuilder: (context, index) {
              final partida = _partidas.isNotEmpty ? _partidas[index] : null;
              final animationIndex = index.clamp(0, 2);
              
              return PartidaCard(
                partida: partida,
                fadeAnimation: _fadeAnimations[animationIndex],
                slideAnimation: _slideAnimations[animationIndex],
                onTap: partida != null ? () => _navegarParaPartida(context, partida) : null,
              );
            },
          ),
    );
  }

  Widget _buildWhatDoYouWantSection() {
    return Column(
      children: [
        const Text('OQUE VOCÊ QUER VER?', style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 28)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OptionButton(
              icon: Icons.sports_soccer,
              label: 'Jogos',
              isSelected: _abaSelecionada == 'Jogos',
              onTap: () => setState(() => _abaSelecionada = 'Jogos'),
            ),
            OptionButton(
              icon: Icons.gavel,
              label: 'Árbitros',
              isSelected: _abaSelecionada == 'Árbitros',
              onTap: () => setState(() => _abaSelecionada = 'Árbitros'),
            ),
            OptionButton(
              icon: Icons.emoji_events,
              label: 'Campeonatos',
              isSelected: _abaSelecionada == 'Campeonatos',
              onTap: () => setState(() => _abaSelecionada = 'Campeonatos'),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildMainGamesSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_abaSelecionada, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _verMeus = !_verMeus),
                  child: Text(_verMeus ? 'Ver Tudo' : 'Ver Meus', style: TextStyle(color: _verMeus ? const Color(0xFFF85C39) : Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
              itemCount: 10,
              itemBuilder: (context, index) => MockListItem(
                sectionType: _abaSelecionada,
              ),
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
        builder: (_) => PartidaRunningScreen(timeA: partida.nomeTimeA, timeB: partida.nomeTimeB),
      ),
    ).then((_) => _carregarDadosIniciais());
  }
}