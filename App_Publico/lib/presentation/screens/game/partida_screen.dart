import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/evento_service.dart';
import '../../../services/firebase_messaging_service.dart';

class JogoDetalhesScreen extends StatefulWidget {
  final String partidaId;
  final DateTime? iniciadaEm;
  final String modalidadeId;
  final String timeA;
  final String timeB;
  final String? EscudoTimeA;
  final String? EscudoTimeB;
  final String placarA;
  final String placarB;
  final String status;

  const JogoDetalhesScreen({
    super.key,
    required this.partidaId,
    this.iniciadaEm,
    required this.modalidadeId,
    required this.timeA,
    required this.timeB,
    this.EscudoTimeA,
    this.EscudoTimeB,
    this.placarA = "0",
    this.placarB = "0",
    this.status = "AO VIVO",
  });

  @override
  State<JogoDetalhesScreen> createState() => _JogoDetalhesScreenState();
}

class _JogoDetalhesScreenState extends State<JogoDetalhesScreen> {
  String _statusAtual = ''; // ← novo

  // ── CRONÔMETRO PÚBLICO ──────────────────────────────────────────────
  Timer? _cronometroTicker;
  int _segundosExibidos = 0;
  bool _cronometroRodando = false;

  // Âncora do último evento confiável
  int _segundosAncora = 0; // tempo_cronometro do último evento (em segundos)
  DateTime? _timestampAncora; // criado_em do último evento
  // ────────────────────────────────────────────────────────────────────

  final SupabaseClient supabase = Supabase.instance.client;
  final EventoService _eventoService = EventoService();

  // Streams para Realtime
  late final Stream<List<Map<String, dynamic>>> _eventosStream;
  late final Stream<Map<String, dynamic>> _partidaStream;
  late Future<List<Map<String, dynamic>>> _futureTipos;
  List<Map<String, dynamic>> _tiposEventosCache = [];

  // Cache local de nomes de atletas (atleta_id → nome)
  final Map<String, String> _atletaNomeCache = {};

  @override
  @override
  void initState() {
    super.initState();

    _partidaStream = supabase
        .from('partidas')
        .stream(primaryKey: ['id'])
        .eq('id', widget.partidaId)
        .limit(1)
        .map((data) => data.first);

    _eventosStream = supabase
        .from('eventos_partida')
        .stream(primaryKey: ['id'])
        .eq('partida_id', widget.partidaId)
        .order('criado_em', ascending: false);

    _futureTipos = _eventoService
        .buscarTiposPorPartida(widget.modalidadeId)
        .then((tipos) {
          if (mounted) setState(() => _tiposEventosCache = tipos);
          return tipos;
        });

    FirebaseMessagingService().subscribeToPartidaTopic(widget.partidaId);

    // Escuta eventos para atualizar âncora do cronômetro
    _eventosStream.listen((eventos) {
      if (!mounted) return;
      _atualizarAncora(eventos);
    });

    // Escuta status da partida para ligar/desligar o ticker
    _partidaStream.listen((dados) {
      if (!mounted) return;
      _atualizarEstadoCronometro(dados['status']?.toString() ?? '');
    });
  }

  @override
  void dispose() {
    _cronometroTicker?.cancel();
    super.dispose();
  }

  /// Retorna o nome amigável do tipo de evento a partir do cache de tipos
  String _friendlyEventName(Map<String, dynamic> ev) {
    final tipoData = _tiposEventosCache.firstWhere(
      (t) => t['id'] == ev['tipo_evento_id'],
      orElse: () => {'nome': 'Evento'},
    );
    final rawName = tipoData['nome']?.toString() ?? 'Evento';
    return EventoService.friendly(rawName);
  }

  // Statuses que significam que o relógio está correndo
  static const _statusRodando = {
    '1° tempo',
    '2° tempo',
    'acréscimo',
    'prorrogação',
  };

  /// Lê o último evento e atualiza a âncora (segundosAncora + timestampAncora)
  void _atualizarAncora(List<Map<String, dynamic>> eventos) {
    final eventoAncora = eventos.firstWhere(
      (e) => e['tempo_cronometro'] != null && e['criado_em'] != null,
      orElse: () => {},
    );

    if (eventoAncora.isEmpty) return;

    final novaAncora = _parseTempoCronometro(
      eventoAncora['tempo_cronometro'].toString(),
    );
    final novoTimestamp = DateTime.tryParse(
      eventoAncora['criado_em'].toString(),
    );

    if (novoTimestamp == null) return;

    // ── NOVO: descobre o tipo do evento mais recente ──────────────────
    final tipoId = eventoAncora['tipo_evento_id']?.toString();
    final tipoData = _tiposEventosCache.firstWhere(
      (t) => t['id'] == tipoId,
      orElse: () => {'nome': ''},
    );
    final rawNome = (tipoData['nome']?.toString() ?? '').toUpperCase();
    final eventoIndicaPausa =
        rawNome.contains('PAUSADA') ||
        rawNome.contains('PAUSA_TECNICA') ||
        rawNome.contains('INTERVALO') ||
        rawNome.contains('FIM_');
    // ─────────────────────────────────────────────────────────────────

    setState(() {
      _segundosAncora = novaAncora;
      _timestampAncora = novoTimestamp;

      if (_cronometroRodando && !eventoIndicaPausa) {
        _segundosExibidos =
            novaAncora +
            DateTime.now().toUtc().difference(novoTimestamp.toUtc()).inSeconds;
      } else {
        _segundosExibidos = novaAncora;
      }
    });

    // ── NOVO: pausa/retoma o ticker baseado no último evento ──────────
    if (eventoIndicaPausa && _cronometroRodando) {
      _cronometroRodando = false;
      _cronometroTicker?.cancel();
    } else if (!eventoIndicaPausa && !_cronometroRodando) {
      // ← NOVO: só religa se o status atual permitir
      final statusPermiteRodar = _statusRodando.contains(
        _statusAtual.toLowerCase(),
      );
      if (!statusPermiteRodar) return;

      // Só religar se o status atual ainda for um status "rodando"
      // (evita religar no intervalo ou fim de partida)
      // _atualizarEstadoCronometro já cuida disso quando o status muda,
      // mas chamamos aqui para o caso de retomada via evento
      _cronometroRodando = true;
      _cronometroTicker?.cancel();
      _cronometroTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_timestampAncora != null) {
          setState(() {
            _segundosExibidos =
                _segundosAncora +
                DateTime.now()
                    .toUtc()
                    .difference(_timestampAncora!.toUtc())
                    .inSeconds;
          });
        }
      });
    }
    // ─────────────────────────────────────────────────────────────────
  }

  /// Liga ou desliga o ticker conforme o status atual da partida
  void _atualizarEstadoCronometro(String status) {
    _statusAtual = status;

    final deveRodar = _statusRodando.contains(status.toLowerCase());

    if (deveRodar && !_cronometroRodando) {
      // Liga o ticker
      _cronometroRodando = true;
      _cronometroTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_timestampAncora != null) {
          setState(() {
            _segundosExibidos =
                _segundosAncora +
                DateTime.now()
                    .toUtc()
                    .difference(_timestampAncora!.toUtc())
                    .inSeconds;
          });
        }
      });
    } else if (!deveRodar && _cronometroRodando) {
      // Desliga o ticker — congela no valor da âncora
      _cronometroRodando = false;
      _cronometroTicker?.cancel();
      setState(() => _segundosExibidos = _segundosAncora);
    }
  }

  /// Converte "MM:SS" → total em segundos
  int _parseTempoCronometro(String tempo) {
    final partes = tempo.split(':');
    if (partes.length != 2) return 0;
    final min = int.tryParse(partes[0]) ?? 0;
    final seg = int.tryParse(partes[1]) ?? 0;
    return min * 60 + seg;
  }

  /// Converte segundos → "MM:SS" para exibição
  String _formatarCronometroPublico(int totalSegundos) {
    final s = totalSegundos.clamp(0, 99 * 60 + 59);
    final min = s ~/ 60;
    final seg = s % 60;
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}";
  }

  /// Busca e retorna o nome do atleta, usando cache local
  Future<String?> _resolveAtletaNome(String? atletaId) async {
    if (atletaId == null || atletaId.isEmpty) return null;

    // Verifica cache primeiro
    if (_atletaNomeCache.containsKey(atletaId)) {
      return _atletaNomeCache[atletaId];
    }

    // Busca do Supabase
    final nome = await _eventoService.buscarNomeAtleta(atletaId);
    if (nome != null) {
      _atletaNomeCache[atletaId] = nome;
    }
    return nome;
  }

  /// Monta a descrição completa do evento com nome amigável e atleta
  Future<String> _buildEventDescription(Map<String, dynamic> ev) async {
    final friendlyName = _friendlyEventName(ev);
    final atletaId = ev['atleta_id']?.toString();
    final atletaSaiId = ev['atleta_sai_id']?.toString();
    final isSubstitution = ev['is_substitution'] == true;
    final descricao = (ev['descricao_detalhada']?.toString() ?? '').trim();

    final parts = <String>[friendlyName];

    if (isSubstitution && atletaId != null && atletaSaiId != null) {
      final nomeEntra = await _resolveAtletaNome(atletaId);
      final nomeSai = await _resolveAtletaNome(atletaSaiId);
      if (nomeEntra != null && nomeSai != null) {
        parts.add('Entra: $nomeEntra, Sai: $nomeSai');
      }
    } else if (atletaId != null) {
      final nome = await _resolveAtletaNome(atletaId);
      if (nome != null) {
        parts.add(nome);
      }
    }

    if (descricao.isNotEmpty) {
      parts.add(descricao);
    }

    return parts.join(' — ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "DETALHES DO JOGO",
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 24),
        ),
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
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF85C39),
                      ),
                    );
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

  Widget _buildScoreHeader({
    required String placarA,
    required String placarB,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFFF85C39)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTeamBadge(widget.timeA, widget.EscudoTimeA),
          Column(
            children: [
              // Placar
              Text(
                "$placarA - $placarB",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              // Badge de status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ), // ← Container fecha AQUI
              // Cronômetro — irmão na Column, não dentro do Container acima
              const SizedBox(height: 8),
              Text(
                _formatarCronometroPublico(_segundosExibidos),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _cronometroRodando ? Colors.white : Colors.white54,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 2,
                ),
              ),

              // Indicador "● AO VIVO" — só aparece quando rodando
              if (_cronometroRodando) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "AO VIVO",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          _buildTeamBadge(widget.timeB, widget.EscudoTimeB),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String nome, String? escudo) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: escudo != null ? NetworkImage(escudo) : null,
          child: escudo == null
              ? Text(
                  nome.isNotEmpty ? nome[0] : "?",
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          child: Text(
            nome,
            textAlign: TextAlign.center,
            maxLines: 3, // Permite até 2 linhas
            softWrap: true, // Habilita a quebra automática
            overflow:
                TextOverflow.ellipsis, // Adiciona "..." se passar de 2 linhas
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height:
                  1.1, // Ajuste opcional para aproximar as linhas e economizar espaço
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventosStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text("Erro ao carregar lances"));

        final eventos = snapshot.data ?? [];
        if (eventos.isEmpty) {
          return const Center(
            child: Text(
              "Aguardando lances da partida...",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 25, 25, 10),
              child: Text(
                "LINHA DO TEMPO AO VIVO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: eventos.length,
                itemBuilder: (context, index) => _buildAnimatedTimelineItem(
                  eventos[index],
                  index,
                  eventos.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Novo método para encapsular a animação de entrada
  Widget _buildAnimatedTimelineItem(
    Map<String, dynamic> ev,
    int index,
    int total,
  ) {
    return TweenAnimationBuilder<double>(
      // Sempre que um item novo for renderizado, ele vai de 0.0 a 1.0
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: _buildTimelineItem(ev, index, total),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> ev, int index, int total) {
    final friendlyName = _friendlyEventName(ev);

    // Determina ícone e cor com base no nome cru
    final tipoData = _tiposEventosCache.firstWhere(
      (t) => t['id'] == ev['tipo_evento_id'],
      orElse: () => {'nome': 'Evento'},
    );
    final String rawNome = (tipoData['nome']?.toString() ?? '').toUpperCase();

    IconData iconData = Icons.info_outline;
    Color iconColor = Colors.grey;

    if (rawNome.contains('GOL') || rawNome.contains('PENALTI_CONVERTIDO')) {
      iconData = Icons.sports_soccer;
      iconColor = Colors.green;
    } else if (rawNome.contains('AMARELO')) {
      iconData = Icons.style;
      iconColor = Colors.amber;
    } else if (rawNome.contains('VERMELHO')) {
      iconData = Icons.style;
      iconColor = Colors.red;
    } else if (rawNome.contains('SUBSTITUIÇÃO')) {
      iconData = Icons.swap_horiz;
      iconColor = Colors.blue;
    } else if (rawNome.contains('FALTA')) {
      iconData = Icons.front_hand;
      iconColor = Colors.orange;
    } else if (rawNome.contains('PENALTI')) {
      iconData = Icons.sports_soccer;
      iconColor = Colors.deepOrange;
    } else if (rawNome.contains('INICIO') ||
        rawNome.contains('FIM') ||
        rawNome.contains('ACRESCIMO') ||
        rawNome.contains('PRORROGACAO') ||
        rawNome.contains('PEDIDO_TEMPO')) {
      iconData = Icons.timer;
      iconColor = const Color(0xFFF85C39);
    } else if (rawNome.contains('WO')) {
      iconData = Icons.cancel;
      iconColor = Colors.red;
    }

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 20,
                color: index == 0 ? Colors.transparent : Colors.grey[300],
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 800),
                scale: 1.0,
                child: Icon(iconData, size: 22, color: iconColor),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: index == total - 1
                      ? Colors.transparent
                      : Colors.grey[300],
                ),
              ),
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
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    "${ev['tempo_cronometro'] ?? "00'00"}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF85C39),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friendlyName,
                          style: TextStyle(
                            fontSize: 10,
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Descrição com nome do atleta (FutureBuilder para async)
                        FutureBuilder<String>(
                          future: _buildEventDescription(ev),
                          builder: (context, snap) {
                            final desc = snap.data ?? '';
                  
                            // Remove o friendlyName do início pois já mostramos acima
                            final cleanDesc = desc.startsWith(friendlyName)
                                ? desc
                                      .substring(friendlyName.length)
                                      .replaceFirst(RegExp(r'^\s*—\s*'), '')
                                : desc;
                            if (cleanDesc.isEmpty)
                              return const SizedBox.shrink();
                            return Text(
                              cleanDesc,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
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
