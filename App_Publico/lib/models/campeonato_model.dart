class Campeonato {
  final String id;
  final String nome;
  final String? nivel;
  final DateTime? dataInicio;
  final DateTime? dataFim;

  Campeonato({
    required this.id,
    required this.nome,
    this.nivel,
    this.dataInicio,
    this.dataFim,
  });

  factory Campeonato.fromMap(Map<String, dynamic> map) {
    return Campeonato(
      id: map['id'],
      nome: map['nome'],
      nivel: map['nivel_campeonato'],
      dataInicio: map['data_inicio'] != null ? DateTime.parse(map['data_inicio']) : null,
      dataFim: map['data_fim'] != null ? DateTime.parse(map['data_fim']) : null,
    );
  }
}