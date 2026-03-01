class Atletica {
  final String id;
  final String nome;
  final String? sigla;
  final String? escudoUrl;
  final String? corPrincipal;
  final String? presidenteId;

  Atletica({
    required this.id,
    required this.nome,
    this.sigla,
    this.escudoUrl,
    this.corPrincipal,
    this.presidenteId,
  });

  factory Atletica.fromMap(Map<String, dynamic> map) {
    return Atletica(
      id: (map['id'] ?? '').toString(),
      nome: (map['nome'] ?? '').toString(),
      sigla: map['sigla']?.toString(),
      // Supabase: escudo_url | possíveis variações
      escudoUrl: (map['escudo_url'] ?? map['escudoUrl'])?.toString(),
      corPrincipal: (map['cor_principal'] ?? map['corPrincipal'])?.toString(),
      presidenteId: (map['presidente_id'] ?? map['presidenteId'])?.toString(),
    );
  }
}

class Equipe {
  final String id;
  final String nome;
  final String atleticaId;
  final Atletica? atletica; // Join (Supabase)

  Equipe({
    required this.id,
    required this.nome,
    required this.atleticaId,
    this.atletica,
  });

  factory Equipe.fromMap(Map<String, dynamic> map) {
    return Equipe(
      id: (map['id'] ?? '').toString(),
      // API: nomeEquipe | Supabase: nome_equipe
      nome: (map['nomeEquipe'] ?? map['nome_equipe'] ?? map['nome'] ?? '').toString(),
      // API: atleticaId | Supabase: atletica_id
      atleticaId: (map['atleticaId'] ?? map['atletica_id'] ?? '').toString(),
      atletica: map['atleticas'] != null
          ? Atletica.fromMap(Map<String, dynamic>.from(map['atleticas']))
          : null,
    );
  }
}
