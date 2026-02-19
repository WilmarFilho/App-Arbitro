class Profile {
  final String id;
  final String? nomeExibicao;
  final String? fotoUrl;
  final String role; // super_admin, admin, arbitro, delegado, presidente_atletica, aluno 

  Profile({
    required this.id,
    this.nomeExibicao,
    this.fotoUrl,
    required this.role,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      nomeExibicao: map['nome_exibicao'],
      fotoUrl: map['foto_url'],
      role: map['role'] ?? 'aluno',
    );
  }
}