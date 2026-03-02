import 'package:flutter/foundation.dart';

import '../models/campeonato_model.dart';
import '../models/modalidade_model.dart';
import '../models/partida_api_model.dart';
import '../models/atletica_equipe_model.dart';
import 'api_client.dart';

class CompeticaoService {
  final _client = ApiClient().dio;

  Future<List<Campeonato>> listarCampeonatos() async {
    try {
      final res = await _client.get('/campeonatos');
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((e) => Campeonato.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('listarCampeonatos error: $e');
    }
    return [];
  }

  Future<List<Modalidade>> listarModalidadesPorCampeonato(String campeonatoId) async {
    try {
      final res = await _client.get('/campeonatos/$campeonatoId/modalidades');
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((e) => Modalidade.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('listarModalidadesPorCampeonato error: $e');
    }
    return [];
  }

  Future<List<Equipe>> listarEquipes({String? campeonatoId, String? modalidadeId, String? atleticaId}) async {
    try {
      final res = await _client.get(
        '/equipes',
        queryParameters: {
          if (campeonatoId != null) 'campeonatoId': campeonatoId,
          if (modalidadeId != null) 'modalidadeId': modalidadeId,
          if (atleticaId != null) 'atleticaId': atleticaId,
        },
      );
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((e) => Equipe.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('listarEquipes error: $e');
    }
    return [];
  }
  
  /// Busca uma equipe específica na API REST (/api/v1/equipes/{id})
  Future<Equipe?> buscarEquipePorId(String id) async {
    try {
      final res = await _client.get('/equipes/$id');
      if (res.statusCode == 200 && res.data is Map) {
        return Equipe.fromMap(Map<String, dynamic>.from(res.data as Map));
      }
    } catch (e) {
      debugPrint('buscarEquipePorId error: $e');
    }
    return null;
  }

  Future<List<PartidaApi>> listarPartidas({String? modalidadeId, String? status}) async {
    try {
      final res = await _client.get(
        '/partidas',
        queryParameters: {
          if (modalidadeId != null) 'modalidadeId': modalidadeId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
        },
      );
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((e) => PartidaApi.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('listarPartidas error: $e');
    }
    return [];
  }
}
