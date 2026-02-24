import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partida_model.dart';
import '../models/arbitro_model.dart';
import '../models/campeonato_model.dart';
import '../models/tipo_evento_model.dart';

class PartidaService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.kyarem.nkwflow.com/api/v1',
      connectTimeout: const Duration(seconds: 5),
    ),
  );

  final _supabase = Supabase.instance.client;

  // CONSTRUCTOR PARA SEMPRE INCLUIR O TOKEN NA REQUISIÇÃO
  PartidaService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _supabase.auth.currentSession?.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('DIO: Enviando Token no Header');
          } else {
            debugPrint('DIO: Nenhum token encontrado na sessão');
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          debugPrint(
            'DIO ERROR[${e.response?.statusCode}]: ${e.response?.data}',
          );
          return handler.next(e);
        },
      ),
    );
  }

  Future<List<dynamic>> buscarDadosPorAba(String aba) async {
    try {
      if (aba == 'Jogos') {
        // AGORA BUSCA TODAS AS PARTIDAS GLOBAIS
        return await listarTodasPartidas();
      } else if (aba == 'Árbitros') {
        final response = await _supabase
            .from('profiles')
            .select('*')
            .eq('role', 'arbitro')
            .order('nome_exibicao');
        return (response as List).map((m) => Arbitro.fromMap(m)).toList();
      } else {
        // Campeonatos
        // Endpoint global da API (sem o sufixo /minhas)
        final response = await _dio.get('/campeonatos');

        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          // 2. Mapeie para o Model de Campeonato que ajustamos antes
          return data.map((m) => Campeonato.fromMap(m)).toList();
        }
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// BUSCA TODAS PARTIDAS
  Future<List<Partida>> listarTodasPartidas() async {
    try {
      // Endpoint global da API (sem o sufixo /minhas)
      final response = await _dio.get('/partidas');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((m) => Partida.fromMap(m)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Erro ao buscar todas as partidas via API: ${e.message}');
      return [];
    }
  }

  /// BUSCA PARTIDAS DO USUÁRIO ( ARBITRO )
  Future<List<Partida>> listarPartidasMinhas() async {
    try {
      final response = await _dio.get('/partidas/minhas');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        debugPrint('oi Dados recebidos da API: $data');

        // Converte o JSON da API para a lista de objetos Partida
        return data.map((m) => Partida.fromMap(m)).toList();
      }

      return [];
    } on DioException catch (e) {
      // Aqui você pode tratar erros de conexão ou 401 (não autorizado)
      debugPrint('Erro ao buscar partidas da API: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Erro inesperado: $e');
      return [];
    }
  }

  /// Salvar novo evento da partida
  Future<void> salvarEvento({
    required String partidaId,
    required String tipoEventoId,
    String? equipeId,
    String? atletaId, // UUID do atleta
    String? atletaSaiId, // UUID do atleta que sai (em caso de substituição)
    required int tempoFormatado, // Texto como "08:15"
    String? descricao,
    bool isSubstitution = false,
  }) async {
    try {
      await _supabase.from('eventos_partida').insert({
        'partida_id': partidaId,
        'tipo_evento_id': tipoEventoId,
        'equipe_id': equipeId,
        'atleta_id': atletaId,
        'atleta_sai_id': atletaSaiId,
        'tempo_cronometro': tempoFormatado,
        'descricao_detalhada': descricao,
        'is_substitution': isSubstitution,
        'criado_em': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Busca tipos de eventos do esporte da modalidade específica
  Future<List<TipoEventoEsporte>> buscarTiposDeEventoDaPartida(
    String modalidadeId,
  ) async {
    try {
      // 1. Busca a modalidade para obter o esporte_id vinculado
      final modalidadeData = await _supabase
          .from('modalidades')
          .select('esporte_id')
          .eq('id', modalidadeId)
          .single();

      final String? esporteId = modalidadeData['esporte_id'];

      if (esporteId == null) return [];

      // 2. Com o esporte_id, buscamos todos os tipos de eventos associados a esse esporte
      // Note: No seu banco a tabela chama-se 'tipos_eventos'
      final List<dynamic> eventosData = await _supabase
          .from('tipos_eventos')
          .select('*')
          .eq('esporte_id', esporteId);

      // 3. Converte para sua lista de modelos
      return eventosData.map((e) => TipoEventoEsporte.fromJson(e)).toList();
    } catch (e) {
      return [];
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
