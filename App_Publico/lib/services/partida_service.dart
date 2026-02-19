import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partida_model.dart';

class PartidaService {
  final _supabase = Supabase.instance.client;

  /// Busca partidas em destaque (ao vivo ou agendadas para hoje)
  Future<List<Partida>> listarPartidasDestaque() async {
    try {
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
          .or('status.eq.em_andamento,status.eq.agendada')
          .order('iniciada_em', ascending: true);

      return (response as List).map((json) => Partida.fromMap(json)).toList();
    } catch (e) {
      print('Erro ao buscar destaques: $e');
      return [];
    }
  }

  /// Busca todas as partidas encerradas (Histórico)
  Future<List<Partida>> listarHistoricoPartidas() async {
    final response = await _supabase
        .from('partidas')
        .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
        .eq('status', 'encerrada')
        .order('iniciada_em', ascending: false);

    return (response as List).map((json) => Partida.fromMap(json)).toList();
  }
}