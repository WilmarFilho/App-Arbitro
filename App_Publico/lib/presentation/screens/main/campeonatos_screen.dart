import 'package:flutter/material.dart';

import '../../../models/campeonato_model.dart';
import '../../../services/competicao_service.dart';
import '../competicao/modalidades_screen.dart';

import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';

class CampeonatosScreen extends StatefulWidget {
  const CampeonatosScreen({super.key});

  @override
  State<CampeonatosScreen> createState() => _CampeonatosScreenState();
}

class _CampeonatosScreenState extends State<CampeonatosScreen> {
  final _service = CompeticaoService();
  late Future<List<Campeonato>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listarCampeonatos();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.listarCampeonatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 18, 22, 10),
                  child: Text(
                    'CAMPEONATOS',
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: 30,
                      letterSpacing: 1.2,
                      color: Color.fromARGB(255, 32, 32, 32),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        )
                      ],
                    ),
                    child: FutureBuilder<List<Campeonato>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFFF85C39)),
                          );
                        }

                        final campeonatos = snap.data ?? [];

                        if (campeonatos.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Nenhum campeonato encontrado.',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _reload,
                                    child: const Text('Tentar novamente'),
                                  )
                                ],
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _reload,
                          color: const Color(0xFFF85C39),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
                            itemCount: campeonatos.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final c = campeonatos[i];
                              return _CampeonatoCard(
                                campeonato: c,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ModalidadesScreen(campeonato: c),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationWidget(currentRoute: '/campeonatos'),
          ),
        ],
      ),
    );
  }
}

class _CampeonatoCard extends StatelessWidget {
  final Campeonato campeonato;
  final VoidCallback onTap;

  const _CampeonatoCard({
    required this.campeonato,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nivel = (campeonato.nivel ?? '').trim();

    String periodo = '';
    if (campeonato.dataInicio != null || campeonato.dataFim != null) {
      final ini = campeonato.dataInicio != null
          ? '${campeonato.dataInicio!.day.toString().padLeft(2, '0')}/${campeonato.dataInicio!.month.toString().padLeft(2, '0')}/${campeonato.dataInicio!.year}'
          : '--/--/----';
      final fim = campeonato.dataFim != null
          ? '${campeonato.dataFim!.day.toString().padLeft(2, '0')}/${campeonato.dataFim!.month.toString().padLeft(2, '0')}/${campeonato.dataFim!.year}'
          : '--/--/----';
      periodo = '$ini  →  $fim';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF85C39).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.emoji_events, color: Color(0xFFF85C39)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campeonato.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (nivel.isNotEmpty || periodo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [if (nivel.isNotEmpty) nivel, if (periodo.isNotEmpty) periodo].join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ]
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
