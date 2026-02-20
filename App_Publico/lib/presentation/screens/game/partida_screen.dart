import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/evento_service.dart';

class JogoDetalhesScreen extends StatefulWidget {
  final String partidaId;
  final String modalidadeId;
  final String timeA;
  final String timeB;
  final String placarA;
  final String placarB;
  final String status;

  const JogoDetalhesScreen({
    super.key,
    required this.partidaId,
    required this.modalidadeId,
    required this.timeA,
    required this.timeB,
    this.placarA = "0",
    this.placarB = "0",
    this.status = "AO VIVO",
  });

  @override
  State<JogoDetalhesScreen> createState() => _JogoDetalhesScreenState();
}

class _JogoDetalhesScreenState extends State<JogoDetalhesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final EventoService _eventoService = EventoService();

  // Streams para Realtime
  late final Stream<List<Map<String, dynamic>>> _eventosStream;
  late final Stream<Map<String, dynamic>> _partidaStream;
  
  late Future<List<Map<String, dynamic>>> _futureTipos;
  List<Map<String, dynamic>> _tiposEventosCache = [];

  @override
  void initState() {
    super.initState();

    // 1. Stream da Partida (para o Placar em tempo real)
    _partidaStream = supabase
        .from('partidas')
        .stream(primaryKey: ['id'])
        .eq('id', widget.partidaId)
        .limit(1)
        .map((data) => data.first);

    // 2. Stream dos Eventos (Linha do tempo)
    _eventosStream = supabase
        .from('eventos_partida')
        .stream(primaryKey: ['id'])
        .eq('partida_id', widget.partidaId)
        .order('criado_em', ascending: false);

    // 3. Cache dos tipos de eventos
    _futureTipos = _eventoService.buscarTiposPorPartida(widget.modalidadeId).then((tipos) {
      if (mounted) setState(() => _tiposEventosCache = tipos);
      return tipos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("DETALHES DO JOGO", 
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 24)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF85C39),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header com StreamBuilder para o placar
          StreamBuilder<Map<String, dynamic>>(
            stream: _partidaStream,
            builder: (context, snapshot) {
              // Se ainda não carregou o stream, usa os dados do widget (estáticos)
              final dados = snapshot.data;
              return _buildScoreHeader(
                placarA: dados?['placar_a']?.toString() ?? widget.placarA,
                placarB: dados?['placar_b']?.toString() ?? widget.placarB,
                status: dados?['status'] ?? widget.status,
              );
            },
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: FutureBuilder(
                future: _futureTipos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFF85C39)));
                  }
                  return _buildTimelineStream();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE INTERFACE ---

  Widget _buildScoreHeader({required String placarA, required String placarB, required String status}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFFF85C39)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTeamBadge(widget.timeA),
          Column(
            children: [
              Text(
                "$placarA - $placarB",
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          _buildTeamBadge(widget.timeB),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String nome) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(nome.isNotEmpty ? nome[0] : "?", 
            style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 80,
          child: Text(nome, 
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

 // ... (mantenha o restante do código igual até o _buildTimelineStream)

  Widget _buildTimelineStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventosStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Erro ao carregar lances"));
        
        final eventos = snapshot.data ?? [];
        if (eventos.isEmpty) {
          return const Center(child: Text("Aguardando lances da partida...", 
            style: TextStyle(color: Colors.grey, fontSize: 16)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 25, 25, 10),
              child: Text("LINHA DO TEMPO AO VIVO",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: eventos.length,
                // Adicionamos uma chave baseada no ID para o Flutter rastrear mudanças
                itemBuilder: (context, index) => _buildAnimatedTimelineItem(
                  eventos[index], 
                  index, 
                  eventos.length
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Novo método para encapsular a animação de entrada
  Widget _buildAnimatedTimelineItem(Map<String, dynamic> ev, int index, int total) {
    return TweenAnimationBuilder<double>(
      // Sempre que um item novo for renderizado, ele vai de 0.0 a 1.0
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            // Faz o item deslizar levemente da esquerda para a direita (de -20 para 0)
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: _buildTimelineItem(ev, index, total),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> ev, int index, int total) {
    final tipoData = _tiposEventosCache.firstWhere(
      (t) => t['id'] == ev['tipo_evento_id'],
      orElse: () => {'nome': 'Evento'},
    );

    final String nomeEvento = tipoData['nome'].toString().toUpperCase();
    IconData iconData = Icons.info_outline;
    Color iconColor = Colors.grey;

    if (nomeEvento.contains('GOL')) { 
      iconData = Icons.sports_soccer; 
      iconColor = Colors.green; 
    }
    else if (nomeEvento.contains('AMARELO')) { iconData = Icons.style; iconColor = Colors.amber; }
    else if (nomeEvento.contains('VERMELHO')) { iconData = Icons.style; iconColor = Colors.red; }
    else if (nomeEvento.contains('SUBSTITUICAO')) { iconData = Icons.swap_horiz; iconColor = Colors.blue; }

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(width: 2, height: 20, color: index == 0 ? Colors.transparent : Colors.grey[300]),
              // Pequena animação de escala no ícone
              AnimatedScale(
                duration: const Duration(milliseconds: 800),
                scale: 1.0,
                child: Icon(iconData, size: 22, color: iconColor),
              ),
              Expanded(child: Container(width: 2, color: index == total - 1 ? Colors.transparent : Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                // Adicionamos uma sombra leve para destacar novos eventos
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Text("${ev['tempo_cronometro'] ?? "00'00"}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF85C39))),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nomeEvento, style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.bold)),
                        Text(ev['descricao_detalhada'] ?? "", 
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}