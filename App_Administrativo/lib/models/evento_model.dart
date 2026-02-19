class TipoEvento {
  final String id;
  final String esporteId;
  final String nome;

  TipoEvento({
    required this.id,
    required this.esporteId,
    required this.nome,
  });

  factory TipoEvento.fromMap(Map<String, dynamic> map) {
    return TipoEvento(
      id: map['id'],
      esporteId: map['esporte_id'],
      nome: map['nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'esporte_id': esporteId,
      'nome': nome,
    };
  }
}

class EventoPartida {
  final String id;
  final String partidaId;
  final String? atletaId;
  final String? equipeId;
  final String tipoEventoId;
  final String? tempoCronometro;
  final String? descricaoDetalhada;
  final DateTime? criadoEm;

  // Campos auxiliares para facilitar a exibição na UI (populados via JOIN)
  final String? nomeAtleta;
  final String? nomeEquipe;
  final String? nomeEvento;

  EventoPartida({
    required this.id,
    required this.partidaId,
    this.atletaId,
    this.equipeId,
    required this.tipoEventoId,
    this.tempoCronometro,
    this.descricaoDetalhada,
    this.criadoEm,
    this.nomeAtleta,
    this.nomeEquipe,
    this.nomeEvento,
  });

  factory EventoPartida.fromMap(Map<String, dynamic> map) {
    return EventoPartida(
      id: map['id'],
      partidaId: map['partida_id'],
      atletaId: map['atleta_id'],
      equipeId: map['equipe_id'],
      tipoEventoId: map['tipo_evento_id'],
      tempoCronometro: map['tempo_cronometro'],
      descricaoDetalhada: map['descricao_detalhada'],
      criadoEm: map['criado_em'] != null 
          ? DateTime.parse(map['criado_em']) 
          : null,
      // Mapeamento de Joins (Supabase trará como objetos aninhados)
      nomeAtleta: map['atletas']?['nome'],
      nomeEquipe: map['equipes']?['nome_equipe'],
      nomeEvento: map['tipos_eventos']?['nome'],
    );
  }
}