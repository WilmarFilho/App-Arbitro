import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
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
  Database? _db;
  Timer? _syncTimer;
  bool _isSyncing = false;

  final Map<String, Equipe> _equipesCache = {};

  PartidaService() {
    _initInterceptors();
    _initLocalDb().then((_) {
      _startSyncTimer();
    });
  }

  // --- INICIALIZAÇÃO DO BANCO LOCAL (SQLITE) ---
  Future<void> _initLocalDb() async {
    try {
      final path = join(await getDatabasesPath(), 'fila_eventos_v2.db');

      // 1. Abre o banco primeiro
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute('''CREATE TABLE fila_eventos (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              partida_id TEXT,
              dados TEXT, 
              criado_em TEXT
            )''');
        },
      );

      // Isso garante que você comece do zero em cada reinicialização do App
      await _db!.delete('fila_eventos');
      debugPrint("SQFlite: Banco inicializado e registros antigos limpos.");
    } catch (e) {
      debugPrint("SQFlite: Erro ao inicializar banco: $e");
    }
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _processarFilaOffline();
    });
  }

  // --- LÓGICA DE SINCRONIZAÇÃO COM DESVIO DE ENDPOINT ---
  Future<void> _processarFilaOffline() async {
    if (_isSyncing || _db == null) return;
    _isSyncing = true;

    try {
      final List<Map<String, dynamic>> pendentes = await _db!.query(
        'fila_eventos',
        orderBy: 'id ASC',
      );
      if (pendentes.isEmpty) {
        _isSyncing = false;
        return;
      }

      // Agrupadores
      Map<String, List<Map<String, dynamic>>> lotesComAtleta = {};
      Map<String, List<int>> idsParaDeletar = {};

      for (var item in pendentes) {
        String pId = item['partida_id'];
        int rowId = item['id'];
        Map<String, dynamic> corpo = jsonDecode(item['dados']);

        // SE NÃO TEM ATLETA: Envia individualmente para o endpoint da partida
        if (corpo['atletaId'] == null) {
          await _enviarEventoSemAtleta(pId, corpo, rowId);
          continue;
        }

        // SE TEM ATLETA: Agrupa para envio em lote
        lotesComAtleta.putIfAbsent(pId, () => []).add(corpo);
        idsParaDeletar.putIfAbsent(pId, () => []).add(rowId);
      }

      // Envia os lotes agrupados (Eventos com Atleta)
      for (var partidaId in lotesComAtleta.keys) {
        await _enviarLoteComAtleta(
          partidaId,
          lotesComAtleta[partidaId]!,
          idsParaDeletar[partidaId]!,
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  // ENDPOINT A: Eventos em Lote (Com Atleta)
  Future<void> _enviarLoteComAtleta(
    String partidaId,
    List<Map<String, dynamic>> lista,
    List<int> ids,
  ) async {
    try {
      debugPrint("=== LOTE COM ATLETA: /partidas/$partidaId/eventos ===");
      debugPrint(jsonEncode(lista));

      final response = await _dio.post(
        '/partidas/$partidaId/eventos',
        data: lista,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _db!.delete('fila_eventos', where: 'id IN (${ids.join(',')})');
      }
    } catch (e) {
      debugPrint("Erro no lote: $e");
    }
  }

  // ENDPOINT B: Evento Individual (Sem Atleta)
  Future<void> _enviarEventoSemAtleta(
    String partidaId,
    Map<String, dynamic> dado,
    int rowId,
  ) async {
    try {
      debugPrint("=== EVENTO SEM ATLETA: /partidas/$partidaId/eventos ===");
      debugPrint(jsonEncode([dado]));

      // O endpoint /eventos espera uma LISTA de eventos, mesmo para 1 item.
      final response = await _dio.post(
        '/partidas/$partidaId/eventos-gerais',
        data: [dado],
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          _db != null) {
        await _db!.delete('fila_eventos', where: 'id = ?', whereArgs: [rowId]);
      }
    } catch (e) {
      debugPrint("Erro evento individual: $e");
    }
  }

  // --- MÉTODO DE ESCRITA (SALVAR NO CACHE) ---
  Future<void> salvarEvento({
    required String partidaId,
    required String tipoEventoId,
    String? equipeId,
    String? atletaId,
    String? atletaSaiId,
    required String tempoFormatado,
    String? descricao,
    bool isSubstitution = false,
  }) async {
    // PAYLOAD EXATO CONFORME SEU SWAGGER

    final Map<String, dynamic> payload = {
      "partidaId": partidaId,
      "equipeId": (equipeId?.isEmpty ?? true) ? null : equipeId,
      "atletaId": (atletaId?.isEmpty ?? true) ? null : atletaId,
      "atletaSaiId": (atletaSaiId?.isEmpty ?? true) ? null : atletaSaiId,
      "isSubstitution": isSubstitution,
      "tipoEventoId": tipoEventoId,
      "tempoCronometro": tempoFormatado,
      "descricaoDetalhada": descricao ?? "",
    };

    if (_db != null) {
      await _db!.insert('fila_eventos', {
        'partida_id': partidaId,
        'dados': jsonEncode(payload),
      });
      _processarFilaOffline();
    }
  }

  // --- INTERCEPTORS ---
  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = _supabase.auth.currentSession;
          final token = session?.accessToken;
          if (token != null) {
            if (session!.isExpired) {
              final response = await _supabase.auth.refreshSession();
              final newToken = response.session?.accessToken;
              if (newToken != null)
                options.headers['Authorization'] = 'Bearer $newToken';
            } else {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
      ),
    );
  }

  // --- MÉTODOS DE BUSCA (COM RETURNS GARANTIDOS) ---

  Future<Equipe?> buscarEquipePorId(String equipeId) async {
    final id = equipeId.trim();
    if (id.isEmpty) return null;

    final cached = _equipesCache[id];
    if (cached != null) return cached;

    try {
      final response = await _dio.get('/equipes/$id');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final equipe = Equipe.fromMap(response.data as Map<String, dynamic>);
        _equipesCache[id] = equipe;
        return equipe;
      }
    } catch (e) {
      debugPrint('Erro buscarEquipePorId($id): $e');
    }
    return null;
  }

  Future<void> _precarregarEquipes(Iterable<String> ids) async {
    final uniques = <String>{};
    for (final raw in ids) {
      final id = raw.trim();
      if (id.isEmpty) continue;
      if (_equipesCache.containsKey(id)) continue;
      uniques.add(id);
    }

    if (uniques.isEmpty) return;

    await Future.wait(uniques.map(buscarEquipePorId));
  }

  Future<List<Partida>> _enriquecerPartidasComEquipes(
    List<Partida> partidas,
  ) async {
    final ids = <String>[];
    for (final p in partidas) {
      ids.add(p.equipeAId);
      ids.add(p.equipeBId);
    }

    await _precarregarEquipes(ids);

    return partidas
        .map(
          (p) => p.copyWith(
            equipeA: p.equipeA ?? _equipesCache[p.equipeAId],
            equipeB: p.equipeB ?? _equipesCache[p.equipeBId],
          ),
        )
        .toList();
  }

  Future<Partida> carregarEquipesDaPartida(Partida partida) async {
    if (partida.equipeA != null && partida.equipeB != null) return partida;

    await _precarregarEquipes([partida.equipeAId, partida.equipeBId]);

    return partida.copyWith(
      equipeA: partida.equipeA ?? _equipesCache[partida.equipeAId],
      equipeB: partida.equipeB ?? _equipesCache[partida.equipeBId],
    );
  }

  Future<List<Partida>> listarTodasPartidas() async {
    try {
      final response = await _dio.get('/partidas');
      if (response.statusCode == 200) {
        final partidas = (response.data as List)
            .map((m) => Partida.fromMap(m))
            .toList();
        return await _enriquecerPartidasComEquipes(partidas);
      }
    } catch (e) {
      debugPrint("Erro listarTodasPartidas: $e");
    }
    return []; // Garante o retorno se falhar ou não entrar no if
  }

  Future<List<Partida>> listarPartidasMinhas() async {
    try {
      final response = await _dio.get('/partidas/minhas');
      if (response.statusCode == 200) {
        final partidas = (response.data as List)
            .map((m) => Partida.fromMap(m))
            .toList();
        return await _enriquecerPartidasComEquipes(partidas);
      }
    } catch (e) {
      debugPrint("Erro listarPartidasMinhas: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> buscarUltimoEventoComTempo(
    String partidaId,
  ) async {
    try {
      final response = await _supabase
          .from('eventos_partida')
          .select('tempo_cronometro, criado_em, tipo_evento_id')
          .eq('partida_id', partidaId)
          .not('tempo_cronometro', 'is', null)
          .isFilter('atleta_id', null) // ← NOVO
          .order('criado_em', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Erro ao buscar último evento: $e');
      return null;
    }
  }

  Future<List<Arbitro>> listarTodosArbitros() async {
    try {
      final response = await _dio.get('/arbitros');
      if (response.statusCode == 200) {
        return (response.data as List).map((m) => Arbitro.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint("Erro listarTodosArbitros: $e");
    }
    return [];
  }

  Future<List<Campeonato>> listarTodosCampeonatos() async {
    try {
      final response = await _dio.get('/campeonatos');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((m) => Campeonato.fromMap(m))
            .toList();
      }
    } catch (e) {
      debugPrint("Erro listarTodosCampeonatos: $e");
    }
    return [];
  }

  Future<List<TipoEventoEsporte>> buscarTiposDeEventoDaPartida(
    String modalidadeId,
  ) async {
    try {
      final resMod = await _dio.get('/modalidades/$modalidadeId');
      final String? esporteId = resMod.data['esporteId'];
      if (esporteId != null) {
        final resEvt = await _dio.get('/esportes/$esporteId/tipos-eventos');
        if (resEvt.statusCode == 200) {
          return (resEvt.data as List)
              .map((e) => TipoEventoEsporte.fromMap(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Erro buscarTiposDeEventoDaPartida: $e');
    }
    return [];
  }

  Future<List<dynamic>> buscarInscritos(String equipeId) async {
    try {
      final response = await _dio.get('/equipes/$equipeId/inscritos');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Erro buscarInscritos: $e');
    }
    return [];
  }

  Future<List<dynamic>> buscarDadosPorAba(String aba) async {
    switch (aba) {
      case 'Jogos':
        return await listarTodasPartidas();
      case 'Árbitros':
        return await listarTodosArbitros();
      case 'Campeonatos':
        return await listarTodosCampeonatos();
      default:
        return [];
    }
  }

  // --- MÉTODOS DE ATUALIZAÇÃO ---

  // No partido_service.dart ou evento_service.dart
  Future<List<Map<String, dynamic>>> buscarEventosDaPartida(
    String partidaId,
  ) async {
    final response = await _supabase
        .from('eventos_partida')
        .select('*, tipo_evento:tipo_evento_id(*)')
        .eq('partida_id', partidaId)
        .order('criado_em', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> atualizarPartida(String partidaId, {String? novoStatus}) async {
    final status = novoStatus?.trim();
    if (status == null || status.isEmpty) return;

    try {
      await _dio.patch('/partidas/$partidaId/status', data: {"status": status});
    } catch (e) {
      debugPrint("Erro atualizar status da partida: $e");
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
