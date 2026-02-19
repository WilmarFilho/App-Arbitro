import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import '../../../services/partida_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/partida_card.dart';
import '../../widgets/home/option_button.dart';
import '../../widgets/home/home_list.dart'; // Certifique-se de criar este arquivo
import '../game/partida_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PartidaService _partidaService = PartidaService();

  // Listas de dados reais
  List<Partida> _partidasDestaque = []; 
  List<dynamic> _itensListaInferior = []; 

  // Controles de estado independentes
  bool _carregandoDestaques = false;
  bool _carregandoListaAba = false;

  // Animações
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  String _abaSelecionada = 'Jogos';
  bool _verMeus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializeAnimations();
    _carregarTudo();
  }

  void _initializeAnimations() {
    _fadeAnimations = List.generate(3, (index) => 
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.2, (index * 0.2) + 0.8, curve: Curves.easeOutCubic),
        ),
      ),
    );

    _slideAnimations = List.generate(3, (index) => 
      Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.2, (index * 0.2) + 0.8, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Carrega os destaques e a lista da aba simultaneamente na abertura
  Future<void> _carregarTudo() async {
    await Future.wait([
      _buscarPartidasDestaque(),
      _buscarDadosAba(),
    ]);
  }

  /// Busca sempre as partidas para o carrossel superior
  Future<void> _buscarPartidasDestaque() async {
    if (mounted) setState(() => _carregandoDestaques = true);
    try {
      final partidas = await _partidaService.listarPartidasDoDia();
      if (mounted) {
        setState(() {
          _partidasDestaque = partidas;
          _carregandoDestaques = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar destaques: $e");
      if (mounted) setState(() => _carregandoDestaques = false);
    }
  }

  /// Busca os dados específicos da aba (Jogos, Árbitros ou Campeonatos)
  Future<void> _buscarDadosAba() async {
    if (mounted) setState(() => _carregandoListaAba = true);
    try {
      final dados = await _partidaService.buscarDadosPorAba(_abaSelecionada);
      if (mounted) {
        setState(() {
          _itensListaInferior = dados;
          _carregandoListaAba = false;
        });
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      debugPrint("Erro ao buscar lista da aba: $e");
      if (mounted) setState(() => _carregandoListaAba = false);
    }
  }

  /// Função chamada ao trocar de aba nos OptionButtons
  void _mudarAba(String novaAba) {
    if (_abaSelecionada == novaAba) return;
    setState(() {
      _abaSelecionada = novaAba;
      _itensListaInferior = []; // Limpa para mostrar o loading específico da lista
    });
    _buscarDadosAba();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(heightFactor: 0.8),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const HomeHeader(),
                _buildCardsSection(), // Seção de Partidas (Fixo)
                const SizedBox(height: 20),
                _buildWhatDoYouWantSection(), // Botões de Seleção
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, 10),
                    child: _buildMainGamesSection(), // Lista Dinâmica
                  ),
                ),
              ],
            ),
          ),
          const BottomNavigationWidget(currentRoute: '/home'),
        ],
      ),
    );
  }

  /// Carrossel Horizontal - SEMPRE PARTIDAS
  Widget _buildCardsSection() {
    return SizedBox(
      height: 155,
      child: _carregandoDestaques && _partidasDestaque.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _partidasDestaque.isEmpty 
              ? const Center(child: Text("Nenhuma partida em destaque", style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _partidasDestaque.length,
                  itemBuilder: (context, index) {
                    final partida = _partidasDestaque[index];
                    final animationIndex = index.clamp(0, 2);

                    return PartidaCard(
                      partida: partida,
                      fadeAnimation: _fadeAnimations[animationIndex],
                      slideAnimation: _slideAnimations[animationIndex],
                      onTap: () => _navegarParaPartida(partida),
                    );
                  },
                ),
    );
  }

  /// Seção de filtros/abas
  Widget _buildWhatDoYouWantSection() {
    return Column(
      children: [
        const Text(
          'O QUE VOCÊ QUER VER?',
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 28),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OptionButton(
              icon: Icons.sports_soccer,
              label: 'Jogos',
              isSelected: _abaSelecionada == 'Jogos',
              onTap: () => _mudarAba('Jogos'),
            ),
            OptionButton(
              icon: Icons.gavel,
              label: 'Árbitros',
              isSelected: _abaSelecionada == 'Árbitros',
              onTap: () => _mudarAba('Árbitros'),
            ),
            OptionButton(
              icon: Icons.emoji_events,
              label: 'Campeonatos',
              isSelected: _abaSelecionada == 'Campeonatos',
              onTap: () => _mudarAba('Campeonatos'),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  /// Lista Vertical - MUDA CONFORME ABA
  Widget _buildMainGamesSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _abaSelecionada,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => setState(() => _verMeus = !_verMeus),
                  child: Text(
                    _verMeus ? 'Ver Tudo' : 'Ver Meus',
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
            child: _carregandoListaAba && _itensListaInferior.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _itensListaInferior.length,
                    itemBuilder: (context, index) {
                      return HomeListItem(
                        item: _itensListaInferior[index],
                        type: _abaSelecionada,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _navegarParaPartida(Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartidaRunningScreen(
          timeA: partida.equipeA?.atletica?.nome ?? 'Time A',
          timeB: partida.equipeB?.atletica?.nome ?? 'Time B',
        ),
      ),
    ).then((_) => _carregarTudo()); // Recarrega tudo ao voltar
  }
}