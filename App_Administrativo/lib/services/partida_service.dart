import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
  Database? _db;
  Timer? _syncTimer;
  bool _isSyncing = false;

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
      debugPrint(
        "=== EVENTO SEM ATLETA: /partidas/$partidaId/evento-geral ===",
      );
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
      "descricaoDetalhada": descricao ?? ""
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

  Future<List<Partida>> listarTodasPartidas() async {
    try {
      final response = await _dio.get('/partidas');
      if (response.statusCode == 200) {
        return (response.data as List).map((m) => Partida.fromMap(m)).toList();
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
        return (response.data as List).map((m) => Partida.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint("Erro listarPartidasMinhas: $e");
    }
    return [];
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

  Future<void> atualizarPartida(
    String partidaId, {
    String? novoStatus,
    int? golsA,
    int? golsB,
  }) async {
    final Map<String, dynamic> dados = {};
    if (novoStatus != null) dados['status'] = novoStatus;
    if (golsA != null) dados['placar_a'] = golsA;
    if (golsB != null) dados['placar_b'] = golsB;

    if (dados.isNotEmpty) {
      try {
        await _supabase.from('partidas').update(dados).eq('id', partidaId);
      } catch (e) {
        debugPrint("Erro atualizarPartida: $e");
      }
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
