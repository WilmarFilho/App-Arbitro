import 'package:supabase_flutter/supabase_flutter.dart';

class EventoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mapeamento de nomes crus do banco → nomes amigáveis para exibição
  static const Map<String, String> friendlyNames = {
    'INICIO_1_TEMPO': 'Início do 1° Tempo',
    'FIM_1_TEMPO': 'Fim do 1° Tempo',
    'INICIO_2_TEMPO': 'Início do 2° Tempo',
    'FIM_PARTIDA': 'Fim da Partida',
    'GOL': '⚽ Gol',
    'FALTA': 'Falta',
    'CARTAO_AMARELO': '🟨 Cartão Amarelo',
    'CARTAO_VERMELHO': '🟥 Cartão Vermelho',
    'SUBSTITUICAO': '🔄 Substituição',
    'PENALTI_MARCADO': 'Pênalti Marcado',
    'PENALTI_CONVERTIDO': '⚽ Pênalti Convertido',
    'PENALTI_PERDIDO': 'Pênalti Perdido',
    'TIRO_LIVRE_DIRETO': 'Tiro Livre Direto',
    'PEDIDO_TEMPO': '⏱️ Pedido de Tempo',
    'WO': 'W.O.',
  };

  /// Retorna o nome amigável do tipo de evento a partir do nome cru do banco
  static String friendly(String? rawName) {
    if (rawName == null || rawName.isEmpty) return 'Evento';
    return friendlyNames[rawName.trim().toUpperCase()] ?? rawName;
  }

  Future<List<Map<String, dynamic>>> buscarTiposPorPartida(
    String modalidadeId,
  ) async {
    try {
      // Busca o esporte_id vinculado à modalidade da partida
      final modalidadeData = await _supabase
          .from('modalidades')
          .select('esporte_id')
          .eq('id', modalidadeId)
          .single();

      final String esporteId = modalidadeData['esporte_id'];

      // Busca os nomes dos eventos configurados para aquele esporte
      final response = await _supabase
          .from('tipos_eventos')
          .select('id, nome')
          .eq('esporte_id', esporteId)
          .order('nome', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Busca o nome de um atleta pelo ID. Retorna null se não encontrado.
  Future<String?> buscarNomeAtleta(String atletaId) async {
    try {
      final data = await _supabase
          .from('atletas')
          .select('nome')
          .eq('id', atletaId)
          .single();
      return data['nome'] as String?;
    } catch (e) {
      return null;
    }
  }
}
