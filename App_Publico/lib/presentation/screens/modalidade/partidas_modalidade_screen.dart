import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/modalidade_model.dart';
import '../../../models/partida_api_model.dart';
import '../../../services/competicao_service.dart';
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
  State<PartidasModalidadeScreen> createState() => _PartidasModalidadeScreenState();
}

enum _FiltroStatus { todas, agendadas, emAndamento, finalizadas }

class _PartidasModalidadeScreenState extends State<PartidasModalidadeScreen> {
  final _service = CompeticaoService();

  bool _loading = true;
  _FiltroStatus _filtro = _FiltroStatus.todas;
  List<PartidaApi> _partidas = [];
  Map<String, String> _equipeNomeById = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);

    // 1) Partidas (API)
    final statusApi = _statusParaApi(_filtro);
    final partidas = await _service.listarPartidas(modalidadeId: widget.modalidade.id, status: statusApi);

    // 2) Montar conjunto de IDs de equipes usadas nas partidas
    final idsEquipes = <String>{};
    for (final p in partidas) {
      final a = p.equipeAId;
      final b = p.equipeBId;
      if (a != null && a.trim().isNotEmpty) idsEquipes.add(a);
      if (b != null && b.trim().isNotEmpty) idsEquipes.add(b);
    }

    // 3) Para cada ID, fazer request `/api/v1/equipes/{id}` via service
    final Map<String, String> nomesEquipes = {};
    await Future.wait(
      idsEquipes.map((id) async {
        final equipe = await _service.buscarEquipePorId(id);
        if (equipe != null && equipe.id.isNotEmpty) {
          nomesEquipes[equipe.id] = equipe.nome;
        }
      }),
    );

    _equipeNomeById = nomesEquipes;

    // 4) Enriquecer nomes das equipes na lista de partidas
    var enriched = partidas
        .map(
          (p) => p.copyWith(
            equipeANome: p.equipeAId != null ? _equipeNomeById[p.equipeAId!] : null,
            equipeBNome: p.equipeBId != null ? _equipeNomeById[p.equipeBId!] : null,
          ),
        )
        .toList();

    // 5) Filtro "Em andamento" (o back-end valida status exato, então filtramos no app)
    if (_filtro == _FiltroStatus.emAndamento) {
      enriched = enriched
          .where((p) {
            final st = p.status.trim().toLowerCase();
            return st != 'agendada' && st != 'finalizada';
          })
          .toList();
    }

    // 6) Ordenação: agendadaPor/iniciadaEm
    enriched.sort((a, b) {
      final da = a.agendadoPara ?? a.iniciadaEm ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.agendadoPara ?? b.iniciadaEm ?? DateTime.fromMillisecondsSinceEpoch(0);
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
        return null; // busca todas e filtra
      case _FiltroStatus.todas:
      default:
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
      default:
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
      body: Column(
        children: [
          _buildHeader(titulo),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF85C39)))
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                            itemCount: _partidas.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _PartidaTile(
                              partida: _partidas[i],
                              onTap: () => _abrirDetalhe(_partidas[i]),
                            ),
                          ),
                  ),
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
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
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  (widget.modalidade.esporteNome ?? '').isNotEmpty
                      ? '${widget.modalidade.esporteNome} • $titulo'
                      : titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
          )
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

  const _PartidaTile({
    required this.partida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeA = partida.equipeANome ?? 'Time A';
    final timeB = partida.equipeBNome ?? 'Time B';

    final st = partida.status.toUpperCase();

    final dt = partida.iniciadaEm ?? partida.agendadoPara;
    final dtStr = dt != null ? DateFormat('dd/MM • HH:mm').format(dt.toLocal()) : '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$timeA  x  $timeB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF85C39).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      st,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF85C39),
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${partida.placarA} - ${partida.placarB}',
                    style: const TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 32, 32, 32),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dtStr.isNotEmpty)
                          Text(
                            dtStr,
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        if ((partida.local ?? '').trim().isNotEmpty)
                          Text(
                            partida.local!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
