class Arbitro {
  final String id;
  final String nome; // Nome amigável no Flutter
  final String? fotoUrl;

  Arbitro({required this.id, required this.nome, this.fotoUrl});

  factory Arbitro.fromMap(Map<String, dynamic> map) {
    return Arbitro(
      id: map['id'],
      // Mapeia a coluna do SQL (snake_case) para a variável do Dart (camelCase)
      nome: map['nome_exibicao'] ?? 'Sem nome', 
      fotoUrl: map['foto_url'],
    );
  }
}