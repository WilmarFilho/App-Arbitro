import 'package:flutter/material.dart';

class Atleta {
  final String id;
  final String atletaId;
  final String? equipeId;
  final String? atleticaId;
  final String nome;
  final int numero;
  final bool ativo;
  
  // Campos que não vem da API
  Offset? posicao;
  Color? corTime;

  Atleta({
    required this.id,
    required this.atletaId,
    this.equipeId,
    this.atleticaId,
    required this.nome,
    required this.numero,
    required this.ativo,
    this.posicao,
    this.corTime,
  });

  factory Atleta.fromMap(Map<String, dynamic> map) {
    return Atleta(
      id: map['id'] ?? '',
      equipeId: map['equipeId'],
      atletaId: map['atletaId'] ?? '',
      atleticaId: map['atleticaId'],
      nome: map['atletaNome'] ?? 'Sem Nome',
      numero: map['numeroCamisa'] ?? 0,
      ativo: map['ativo'] ?? false,
    );
  }
}