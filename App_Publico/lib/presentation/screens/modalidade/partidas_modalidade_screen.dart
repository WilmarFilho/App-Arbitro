import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/modalidade_model.dart';
import '../../../models/partida_api_model.dart';
import '../../../services/competicao_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../game/partida_screen.dart';

class PartidasModalidadeScreen extends StatefulWidget {
  final Modalidade modalidade;
  final String campeonatoNome;

  const PartidasModalidadeScreen({
    super.key,
    required this.modalidade,
    required this.campeonatoNome,
  });

  @override
  State<PartidasModalidadeScreen> createState() =>
      _PartidasModalidadeScreenState();
}

enum _FiltroStatus { todas, agendadas, emAndamento, finalizadas }

// ✅ Struct auxiliar para guardar nome + escudo da equipe
class _DadosEquipe {
  final String nome;
  final String? escudoUrl;
  const _DadosEquipe({required this.nome, this.escudoUrl});
}

class _PartidasModalidadeScreenState extends State<PartidasModalidadeScreen> {
  final _service = CompeticaoService();

  bool _loading = true;
  _FiltroStatus _filtro = _FiltroStatus.todas;
  List<PartidaApi> _partidas = [];

  // ✅ Mapa agora guarda nome + escudo
  Map<String, _DadosEquipe> _equipeById = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);

    // 1) Partidas (API)
    final statusApi = _statusParaApi(_filtro);
    final partidas = await _service.listarPartidas(
      modalidadeId: widget.modalidade.id,
      status: statusApi,
    );

    // 2) Montar conjunto de IDs de equipes usadas nas partidas
    final idsEquipes = <String>{};
    for (final p in partidas) {
      final a = p.equipeAId;
      final b = p.equipeBId;
      if (a != null && a.trim().isNotEmpty) idsEquipes.add(a);
      if (b != null && b.trim().isNotEmpty) idsEquipes.add(b);
    }

    // 3) Para cada ID, buscar equipe e guardar nome + escudo
    final Map<String, _DadosEquipe> dadosEquipes = {};
    await Future.wait(
      idsEquipes.map((id) async {
        final equipe = await _service.buscarEquipePorId(id);
        if (equipe != null && equipe.id.isNotEmpty) {
          dadosEquipes[equipe.id] = _DadosEquipe(
            nome: equipe.nome,
            // ✅ Ajuste o campo conforme seu modelo — pode ser:
            // equipe.atleticaEscudoUrl, equipe.escudoUrl, equipe.logoUrl, etc.
            escudoUrl: equipe.atleticaEscudoUrl,
          );
        }
      }),
    );

    _equipeById = dadosEquipes;

    // 4) Enriquecer nomes E escudos das equipes na lista de partidas
    var enriched = partidas
        .map(
          (p) => p.copyWith(
            equipeANome: p.equipeAId != null
                ? _equipeById[p.equipeAId!]?.nome
                : null,
            equipeBNome: p.equipeBId != null
                ? _equipeById[p.equipeBId!]?.nome
                : null,
            // ✅ Novos campos — adicione-os ao copyWith do seu PartidaApi
            equipeAEscudo: p.equipeAId != null
                ? _equipeById[p.equipeAId!]?.escudoUrl
                : null,
            equipeBEscudo: p.equipeBId != null
                ? _equipeById[p.equipeBId!]?.escudoUrl
                : null,
          ),
        )
        .toList();

    // 5) Filtro "Em andamento"
    if (_filtro == _FiltroStatus.emAndamento) {
      enriched = enriched.where((p) {
        final st = p.status.trim().toLowerCase();
        return st != 'agendada' && st != 'finalizada';
      }).toList();
    }

    // 6) Ordenação
    enriched.sort((a, b) {
      final da =
          a.agendadoPara ??
          a.iniciadaEm ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db =
          b.agendadoPara ??
          b.iniciadaEm ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    if (!mounted) return;
    setState(() {
      _partidas = enriched;
      _loading = false;
    });
  }

  String? _statusParaApi(_FiltroStatus filtro) {
    switch (filtro) {
      case _FiltroStatus.agendadas:
        return 'agendada';
      case _FiltroStatus.finalizadas:
        return 'finalizada';
      case _FiltroStatus.emAndamento:
        return null;
      case _FiltroStatus.todas:
        return null;
    }
  }

  String _tituloFiltro(_FiltroStatus filtro) {
    switch (filtro) {
      case _FiltroStatus.agendadas:
        return 'Agendadas';
      case _FiltroStatus.emAndamento:
        return 'Em andamento';
      case _FiltroStatus.finalizadas:
        return 'Finalizadas';
      case _FiltroStatus.todas:
        return 'Todas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = (widget.modalidade.nome ?? 'Modalidade').trim().isNotEmpty
        ? widget.modalidade.nome!
        : 'Modalidade';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(fontFamily: 'Bebas Neue', fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF85C39),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(titulo),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF85C39),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        color: const Color(0xFFF85C39),
                        child: _partidas.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'Nenhuma partida encontrada.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  100,
                                ),
                                itemCount: _partidas.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) => _PartidaTile(
                                  partida: _partidas[i],
                                  onTap: () => _abrirDetalhe(_partidas[i]),
                                ),
                              ),
                      ),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationWidget(currentRoute: '/modalidades'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String titulo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.campeonatoNome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (widget.modalidade.esporteNome ?? '').isNotEmpty
                      ? '${widget.modalidade.esporteNome} • $titulo'
                      : titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_FiltroStatus>(
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (v) {
              setState(() => _filtro = v);
              _carregar();
            },
            itemBuilder: (context) {
              return _FiltroStatus.values
                  .map(
                    (v) => PopupMenuItem<_FiltroStatus>(
                      value: v,
                      child: Text(_tituloFiltro(v)),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
    );
  }

  void _abrirDetalhe(PartidaApi p) {
    final timeA = p.equipeANome ?? 'Time A';
    final timeB = p.equipeBNome ?? 'Time B';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JogoDetalhesScreen(
          partidaId: p.id,
          modalidadeId: p.modalidadeId ?? widget.modalidade.id,
          timeA: timeA,
          timeB: timeB,
          // ✅ Escudos enriquecidos
          EscudoTimeA: p.equipeAEscudo,
          EscudoTimeB: p.equipeBEscudo,
          status: p.status,
          placarA: p.placarA.toString(),
          placarB: p.placarB.toString(),
        ),
      ),
    );
  }
}

class _PartidaTile extends StatelessWidget {
  final PartidaApi partida;
  final VoidCallback onTap;

  const _PartidaTile({required this.partida, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeA = partida.equipeANome ?? 'Time A';
    final timeB = partida.equipeBNome ?? 'Time B';
    final escudoA = partida.equipeAEscudo ?? '';
    final escudoB = partida.equipeBEscudo ?? '';

    final st = partida.status.toUpperCase();
    final isFinalizada = partida.status.trim().toLowerCase() == 'finalizada';
    final isAoVivo =
        partida.status.trim().toLowerCase() != 'agendada' && !isFinalizada;

    final dt = partida.iniciadaEm ?? partida.agendadoPara;
    final dtStr = dt != null
        ? DateFormat('dd/MM • HH:mm').format(dt.toLocal())
        : '';

    final badgeColor = isAoVivo
        ? Colors.green
        : isFinalizada
        ? Colors.grey
        : const Color(0xFFF85C39);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            children: [
              // ── Badge + data ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (dtStr.isNotEmpty)
                    Text(
                      dtStr,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAoVivo) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          st,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Times + Placar ────────────────────────────────────────
              Row(
                children: [
                  // Time A
                  Expanded(
                    child: _buildTeamBlock(
                      escudoA,
                      timeA,
                      CrossAxisAlignment.start,
                    ),
                  ),

                  // Placar central
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          '${partida.placarA}  –  ${partida.placarB}',
                          style: const TextStyle(
                            fontFamily: 'Bebas Neue',
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: 2,
                          ),
                        ),
                        if ((partida.local ?? '').trim().isNotEmpty)
                          Text(
                            partida.local!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Time B
                  Expanded(
                    child: _buildTeamBlock(
                      escudoB,
                      timeB,
                      CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamBlock(
    String url,
    String nome,
    CrossAxisAlignment alignment,
  ) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
          child: url.isEmpty
              ? Text(
                  nome.isNotEmpty ? nome[0] : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          nome,
          maxLines: 2,
          textAlign: alignment == CrossAxisAlignment.start
              ? TextAlign.left
              : TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildEscudo(String url, String nome) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(
              nome.isNotEmpty ? nome[0] : '?',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            )
          : null,
    );
  }
}
