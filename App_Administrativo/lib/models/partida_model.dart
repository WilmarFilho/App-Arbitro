import 'package:kyarem_eventos/models/atletica_equipe_model.dart';

class Partida {
  final String id;
  final String modalidadeId;
  final String status;
  final int placarA;
  final int placarB;
  final String? local;
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;
  final DateTime? agendadaPara;
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
    this.encerradaEm,
    this.agendadaPara,
    this.equipeA,
    this.equipeB,
  });

  factory Partida.fromMap(Map<String, dynamic> map) {
    // A API agrupa os dados detalhados dentro de snapshotSumula
    final sumula = map['snapshotSumula'] as Map<String, dynamic>?;

    return Partida(
      id: map['id'] ?? '',
      modalidadeId: map['modalidadeId'] ?? '',
      status: sumula?['status'] ?? map['status'] ?? 'agendada',
      placarA: map['placarA'] ?? 0,
      placarB: map['placarB'] ?? 0,
      local: map['local'] ?? '',

      // Tratamento de Datas (API usa camelCase e ISO8601)
      iniciadaEm: map['iniciadaEm'] != null
          ? DateTime.tryParse(map['iniciadaEm'])
          : null,
      encerradaEm: map['encerradaEm'] != null
          ? DateTime.tryParse(map['encerradaEm'])
          : null,
      agendadaPara: map['agendadoPara'] != null
          ? DateTime.tryParse(map['agendadoPara'])
          : null,

      // Mapeamento das Equipes (Estão dentro de snapshotSumula)
      equipeA: sumula?['equipeA'] != null
          ? Equipe.fromMap(sumula!['equipeA'])
          : null,
      equipeB: sumula?['equipeB'] != null
          ? Equipe.fromMap(sumula!['equipeB'])
          : null,
    );
  }
}
