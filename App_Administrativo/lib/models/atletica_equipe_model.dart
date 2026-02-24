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
      id: map['id'],
      nome: map['nome'],
      sigla: map['sigla'],
      escudoUrl: map['escudo_url'],
      corPrincipal: map['cor_principal'],
      presidenteId: map['presidente_id'],
    );
  }
}

class Equipe {
  final String id;
  final String nome;
  final String atleticaId;
  final Atletica?
  atletica; // Relacionamento para facilitar o acesso ao escudo/cor

  Equipe({
    required this.id,
    required this.nome,
    required this.atleticaId,
    this.atletica,
  });

  factory Equipe.fromMap(Map<String, dynamic> map) {
    return Equipe(
      id: map['id'] ?? '',
      // No seu JSON a chave é "nomeEquipe" e não "nome"
      nome: map['nomeEquipe'] ?? 'Time Desconhecido',
      atleticaId: map['atleticaId'] ?? '',
    );
  }
}
