import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partida_model.dart';
import '../models/arbitro_model.dart';
import '../models/campeonato_model.dart';

class PartidaService {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> buscarDadosPorAba(String aba) async {
    try {
      if (aba == 'Jogos') {
        return await listarPartidasDoDia();
      } else if (aba == 'Árbitros') {
        final response = await _supabase
            .from('profiles')
            .select('*')
            .eq('role', 'arbitro')
            .order('nome_exibicao');
        return (response as List).map((m) => Arbitro.fromMap(m)).toList();
      } else {
        // Campeonatos
        final response = await _supabase
            .from('campeonatos')
            .select('*')
            .order('nome');
        return (response as List).map((m) => Campeonato.fromMap(m)).toList();
      }
    } catch (e) {
      return [];
    }
  }

  /// Busca as partidas diretamente do banco via Service
  Future<List<Partida>> listarPartidasDoDia() async {
    try {
      // Fazemos a query complexa aqui, incluindo os joins necessários
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
          .order('iniciada_em', ascending: true);

      // Converte a lista de Maps em uma lista de objetos Partida
      final partidas = (response as List)
          .map((m) => Partida.fromMap(m))
          .toList();

      // Regra de negócio: Você pode filtrar apenas as que não foram encerradas, por exemplo
      return partidas;
    } catch (e) {
      print('Erro ao buscar partidas no Service: $e');
      return []; // Retorna lista vazia em caso de erro para não quebrar a UI
    }
  }

  /// Exemplo de lógica para "Ver Meus" (filtros locais)
  List<Partida> filtrarPorAtletica(List<Partida> lista, String atleticaId) {
    return lista
        .where(
          (p) =>
              p.equipeA?.atleticaId == atleticaId ||
              p.equipeB?.atleticaId == atleticaId,
        )
        .toList();
  }
}
