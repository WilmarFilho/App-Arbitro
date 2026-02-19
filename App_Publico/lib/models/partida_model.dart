import 'package:kyarem_eventos_publico/models/atletica_equipe_model.dart';

class Partida {
  final String id;
  final String modalidadeId;
  final String status; // agendada, em_andamento, encerrada [cite: 36]
  final int placarA;
  final int placarB;
  final String? local;
  final DateTime? iniciadaEm;
  final Equipe? equipeA;
  final Equipe? equipeB;

  Partida({
    required this.id,
    required this.modalidadeId,
    required this.status,
    this.placarA = 0,
    this.placarB = 0,
    this.local,
    this.iniciadaEm,
    this.equipeA,
    this.equipeB,
  });

  factory Partida.fromMap(Map<String, dynamic> map) {
    return Partida(
      id: map['id'],
      modalidadeId: map['modalidade_id'],
      status: map['status'] ?? 'agendada',
      placarA: map['placar_a'] ?? 0,
      placarB: map['placar_b'] ?? 0,
      local: map['local'],
      iniciadaEm: map['iniciada_em'] != null ? DateTime.parse(map['iniciada_em']) : null,
      // No Supabase, as equipes virão como objetos aninhados se usarmos o select correto
      equipeA: map['equipe_a'] != null ? Equipe.fromMap(map['equipe_a']) : null,
      equipeB: map['equipe_b'] != null ? Equipe.fromMap(map['equipe_b']) : null,
    );
  }
}