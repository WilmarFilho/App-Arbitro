enum StatusSumula { pendente, emAndamento, encerrada }

class Sumula {
  final String id;
  int placarTimeA;
  int placarTimeB;
  StatusSumula status;
  List<Map<String, dynamic>> eventos; // Lista de lances (gols, cartões)

  Sumula({
    required this.id,
    this.placarTimeA = 0,
    this.placarTimeB = 0,
    this.status = StatusSumula.pendente,
    this.eventos = const [],
  });
}