import 'package:flutter/material.dart';

class EventoPartida {
  final String tipo;
  final String? jogadorNome;
  final int? jogadorNumero;
  final Color? corTime;
  final String horario;
  final String? observacao;

  EventoPartida({
    required this.tipo,
    required this.horario,
    this.jogadorNome,
    this.jogadorNumero,
    this.corTime,
    this.observacao,
  });

  /// Getter que traduz o tipo técnico para uma string amigável para a UI
  String get descricao {
    switch (tipo) {
      case 'INICIO_1_TEMPO':
        return '🟢 Início do 1º Tempo';
      case 'FIM_1_TEMPO':
        return '🏁 Fim do 1º Tempo';
      case 'INTERVALO':
        return '☕ Partida no Intervalo';
      case 'INICIO_2_TEMPO':
        return '🟢 Início do 2º Tempo';
      case 'PARTIDA_PAUSADA':
        return '⏸️ Partida Pausada';
      case 'PARTIDA_RETOMADA':
        return '▶️ Partida Retomada';
      case 'PAUSA_TECNICA':
        return '⏱️ Pausa Técnica';
      case 'FIM_PAUSA_TECNICA':
        return '⌛ Fim da Pausa Técnica';
      case 'ACRESCIMO':
        return '➕ Partida em Acréscimo';
      case 'ACRESCIMO_DADO':
        return '⏱️ Acréscimo concedido';
      case 'PRORROGACAO':
        return '🏟️ Partida em Prorrogação';
      case 'PRORROGACAO_DADA':
        return '⏱️ Prorrogação concedida';
      case 'FIM_PARTIDA':
        return '🏁 Fim de Jogo';
      case 'SUBSTITUICAO':
        return '🔄 Substituição';
      case 'GOL':
        return '⚽ GOL!';
      case 'CARTAO_AMARELO':
        return '🟨 Cartão Amarelo';
      case 'CARTAO_VERMELHO':
        return '🟥 Cartão Vermelho';
      default:
        // Caso seja um evento de jogador não mapeado explicitamente acima
        if (jogadorNumero != null) {
          return '$tipo (#$jogadorNumero)';
        }
        return tipo;
    }
  }

  /// Verifica se o evento é um evento de sistema (sem jogador)
  bool get isSistematizado => jogadorNome == null;

  String get descricaoCompleta {
    final obs = observacao?.trim() ?? '';
    if (obs.isEmpty) return descricao;
    return '$descricao • $obs';
  }
}