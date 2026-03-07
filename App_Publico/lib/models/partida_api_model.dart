class PartidaApi {
  final String id;
  final String? modalidadeId;
  final String? equipeAId;
  final String? equipeBId;
  final String status;
  final DateTime? agendadoPara;
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;
  final String? local;
  final int placarA;
  final int placarB;

  /// Campos enriquecidos (UI)
  final String? equipeANome;
  final String? equipeBNome;
  final String? equipeAEscudo;
  final String? equipeBEscudo;

  PartidaApi({
    required this.id,
    this.modalidadeId,
    this.equipeAId,
    this.equipeBId,
    required this.status,
    this.agendadoPara,
    this.iniciadaEm,
    this.encerradaEm,
    this.local,
    this.placarA = 0,
    this.placarB = 0,
    this.equipeANome,
    this.equipeBNome,
    this.equipeAEscudo,
    this.equipeBEscudo,
  });

  factory PartidaApi.fromMap(Map<String, dynamic> map) {
    return PartidaApi(
      id: (map['id'] ?? '').toString(),
      modalidadeId: map['modalidadeId']?.toString(),
      equipeAId: map['equipeAId']?.toString(),
      equipeBId: map['equipeBId']?.toString(),
      status: (map['status'] ?? 'agendada').toString(),
      agendadoPara: _parseDate(map['agendadoPara']),
      iniciadaEm: _parseDate(map['iniciadaEm']),
      encerradaEm: _parseDate(map['encerradaEm']),
      local: map['local']?.toString(),
      placarA: _parseInt(map['placarA']) ?? 0,
      placarB: _parseInt(map['placarB']) ?? 0,
    );
  }

  PartidaApi copyWith({
    String? equipeANome,
    String? equipeBNome,
    String? equipeAEscudo,
    String? equipeBEscudo,
  }) {
    return PartidaApi(
      id: id,
      modalidadeId: modalidadeId,
      equipeAId: equipeAId,
      equipeBId: equipeBId,
      status: status,
      agendadoPara: agendadoPara,
      iniciadaEm: iniciadaEm,
      encerradaEm: encerradaEm,
      local: local,
      placarA: placarA,
      placarB: placarB,
      equipeANome: equipeANome ?? this.equipeANome,
      equipeBNome: equipeBNome ?? this.equipeBNome,
      equipeAEscudo: equipeAEscudo ?? this.equipeAEscudo,
      equipeBEscudo: equipeBEscudo ?? this.equipeBEscudo,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
