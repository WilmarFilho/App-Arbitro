import 'dart:convert';

class Modalidade {
  final String id;

  // Identificadores
  final String? campeonatoId;
  final String? campeonatoNome;
  final String? esporteId;
  final String? esporteNome;

  // Dados
  final String? nome;
  final int? tempoPartidaMinutos;
  final Map<String, dynamic>? regras;

  // Campo existente no Supabase (se houver)
  final String? genero;

  Modalidade({
    required this.id,
    this.campeonatoId,
    this.campeonatoNome,
    this.esporteId,
    this.esporteNome,
    this.nome,
    this.tempoPartidaMinutos,
    this.regras,
    this.genero,
  });

  factory Modalidade.fromMap(Map<String, dynamic> map) {
    return Modalidade(
      id: (map['id'] ?? '').toString(),
      // API: campeonatoId | Supabase: campeonato_id
      campeonatoId: (map['campeonatoId'] ?? map['campeonato_id'])?.toString(),
      campeonatoNome: map['campeonatoNome']?.toString(),
      // API: esporteId | Supabase: esporte_id
      esporteId: (map['esporteId'] ?? map['esporte_id'])?.toString(),
      // API: esporteNome | Supabase join: esportes.nome
      esporteNome: (map['esporteNome'] ?? map['esportes']?['nome'])?.toString(),
      nome: map['nome']?.toString(),
      tempoPartidaMinutos: _parseInt(map['tempoPartidaMinutos'] ?? map['tempo_partida_minutos']),
      regras: _parseRegras(map['regrasJson'] ?? map['regras_json']),
      genero: map['genero']?.toString(),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static Map<String, dynamic>? _parseRegras(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}
