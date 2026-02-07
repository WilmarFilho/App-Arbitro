import 'sumula_model.dart';

class Partida {
  final String id;
  final String nomeTimeA;
  final String nomeTimeB;
  final List<String> atletasTimeA;
  final List<String> atletasTimeB;
  final DateTime dataHora;
  final Sumula sumula; // Toda partida tem uma súmula vinculada

  Partida({
    required this.id,
    required this.nomeTimeA,
    required this.nomeTimeB,
    required this.atletasTimeA,
    required this.atletasTimeB,
    required this.dataHora,
    required this.sumula,
  });
}