// lib/models/partida_model.dart
class Partida {
  final String id;
  final String nomeTimeA;
  final String nomeTimeB;
  final String status;
  final String placarA;
  final String placarB;

  Partida({
    required this.id,
    required this.nomeTimeA,
    required this.nomeTimeB,
    this.status = "00:00",
    this.placarA = "0",
    this.placarB = "0",
  });
}