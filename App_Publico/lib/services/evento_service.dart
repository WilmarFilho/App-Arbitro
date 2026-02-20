import 'package:supabase_flutter/supabase_flutter.dart';

class EventoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> buscarTiposPorPartida(String modalidadeId) async {
    try {
      // Busca o esporte_id vinculado à modalidade da partida [cite: 7]
      final modalidadeData = await _supabase
          .from('modalidades')
          .select('esporte_id')
          .eq('id', modalidadeId)
          .single();

      final String esporteId = modalidadeData['esporte_id'];

      // Busca os nomes dos eventos configurados para aquele esporte [cite: 13]
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
}