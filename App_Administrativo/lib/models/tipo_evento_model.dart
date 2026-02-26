class TipoEventoEsporte {
  final String id;
  final String esporteId;
  final String nome;
  final int? idx; 

  TipoEventoEsporte({
    required this.id,
    required this.esporteId,
    required this.nome,
    this.idx,
  });

  // Alterado para 'fromMap' para seguir o padrão de nomes da sua nova API
  factory TipoEventoEsporte.fromMap(Map<String, dynamic> json) {
    return TipoEventoEsporte(
      id: json['id'] as String? ?? '',
      // Ajustado: A API retorna 'esporteId' e não 'esporte_id'
      esporteId: json['esporteId'] as String? ?? '', 
      nome: json['nome'] as String? ?? '',
      idx: json['idx'] as int?, 
    );
  }

  // Mapeia de volta para o formato esperado pela API se necessário
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'esporteId': esporteId,
      'nome': nome,
      if (idx != null) 'idx': idx,
    };
  }

  /// Helper para exibir o nome formatado (ex: "CARTAO_AMARELO" -> "Cartao amarelo")
  String get nomeFormatado {
    if (nome.isEmpty) return "";
    
    // Substitui underscores por espaços
    String formatada = nome.replaceAll('_', ' ').toLowerCase();
    
    // Coloca a primeira letra em maiúsculo
    return formatada.replaceFirst(formatada[0], formatada[0].toUpperCase());
  }

  /// Método de conveniência para manter compatibilidade com nomes antigos
  factory TipoEventoEsporte.fromJson(Map<String, dynamic> json) => TipoEventoEsporte.fromMap(json);
}