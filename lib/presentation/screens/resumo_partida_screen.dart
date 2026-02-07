import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/models/partida_model.dart';
import '../../data/models/evento_model.dart';
import '../../data/repositories/partida_repository.dart';
import '../../services/pdf_service.dart';

class ResumoPartidaScreen extends StatefulWidget {
  final Partida partida;

  const ResumoPartidaScreen({super.key, required this.partida});

  @override
  State<ResumoPartidaScreen> createState() => _ResumoPartidaScreenState();
}

class _ResumoPartidaScreenState extends State<ResumoPartidaScreen> {
  final PartidaRepository _repository = PartidaRepository();
  List<Evento> _eventos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    final eventos = await _repository.buscarEventosDaSumula(
      widget.partida.sumula.id,
    );
    setState(() {
      _eventos = eventos;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Resumo da Partida"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Placar Final Glass
                  _buildPlacarFinal(),
                  const SizedBox(height: 30),

                  const Text(
                    "CRONOLOGIA DA PARTIDA",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Lista de Eventos Glass
                  Expanded(child: _buildListaEventos()),

                  const SizedBox(height: 20),

                  // Botão Gerar PDF
                  _buildBotaoPDF(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlacarFinal() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _timeInfo(
                widget.partida.nomeTimeA,
                widget.partida.sumula.placarTimeA,
                Colors.blueAccent,
              ),
              const Text(
                "VS",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _timeInfo(
                widget.partida.nomeTimeB,
                widget.partida.sumula.placarTimeB,
                Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeInfo(String nome, int placar, Color cor) {
    return Column(
      children: [
        Text(
          nome,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "$placar",
          style: TextStyle(
            color: cor,
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildListaEventos() {
    if (_eventos.isEmpty)
      return const Center(
        child: Text(
          "Nenhum lance registrado",
          style: TextStyle(color: Colors.white38),
        ),
      );

    return ListView.builder(
      itemCount: _eventos.length,
      itemBuilder: (context, index) {
        final ev = _eventos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _getIconeEvento(ev.tipo),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ev.atletaNome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ev.tipo,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ev.timestamp.toString().substring(11, 16),
                style: const TextStyle(color: Colors.white24),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getIconeEvento(String tipo) {
    if (tipo == 'GOL')
      return const Icon(Icons.sports_soccer, color: Colors.greenAccent);
    if (tipo == 'AMARELO')
      return const Icon(Icons.style, color: Colors.amberAccent);
    return const Icon(Icons.style, color: Colors.redAccent);
  }

  Widget _buildBotaoPDF() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Mostra um loading ou feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Preparando documento...")),
          );

          // Chama o serviço passando a partida e a lista de eventos que já temos na tela
          await PdfService.gerarSumulaPdf(widget.partida, _eventos);
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("GERAR SÚMULA OFICIAL (PDF)"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
