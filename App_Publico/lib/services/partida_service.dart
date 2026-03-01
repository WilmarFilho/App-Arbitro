import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partida_model.dart';

class PartidaService {
  final _supabase = Supabase.instance.client;

  /// Busca partidas em destaque (em andamento)
  ///
  /// Observação: No back-end o status "em andamento" é qualquer status válido
  /// diferente de "agendada" e "finalizada".
  Future<List<Partida>> listarPartidasDestaque() async {
    try {
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
          .neq('status', 'agendada')
          .neq('status', 'finalizada')
          .order('iniciada_em', ascending: false);

      return (response as List).map((json) => Partida.fromMap(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar destaques: $e');
      return [];
    }
  }

  /// Busca todas as partidas finalizadas (Histórico)
  Future<List<Partida>> listarHistoricoPartidas() async {
    try {
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
          .eq('status', 'finalizada')
          .order('encerrada_em', ascending: false);

      return (response as List).map((json) => Partida.fromMap(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar histórico: $e');
      return [];
    }
  }
}
