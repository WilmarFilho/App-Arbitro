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
      final path = join(await getDatabasesPath(), 'fila_eventos.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute(
            '''CREATE TABLE fila_eventos (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              dados TEXT, 
              tentativas INTEGER DEFAULT 0,
              criado_em TEXT
            )''',
          );
        },
      );
      debugPrint("SQFlite: Banco de dados inicializado.");
    } catch (e) {
      debugPrint("SQFlite: Erro ao inicializar banco: $e");
    }
  }

  // Timer que tenta sincronizar a cada 30 segundos
  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _processarFilaOffline();
    });
  }

  // --- LÓGICA DA FILA ---

  Future<void> _processarFilaOffline() async {
    if (_isSyncing || _db == null) return;
    
    _isSyncing = true;
    try {
      final List<Map<String, dynamic>> pendentes = await _db!.query(
        'fila_eventos', 
        orderBy: 'id ASC', 
        limit: 10
      );

      if (pendentes.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint("Fila: Tentando sincronizar ${pendentes.length} eventos pendentes...");

      for (var item in pendentes) {
        final int id = item['id'];
        final Map<String, dynamic> dados = jsonDecode(item['dados']);

        try {
          // Tenta inserir no Supabase
          await _supabase.from('eventos_partida').insert(dados);
          
          // Se sucesso, remove da fila local
          await _db!.delete('fila_eventos', where: 'id = ?', whereArgs: [id]);
          debugPrint("Fila: Evento ID $id sincronizado com sucesso.");
        } catch (e) {
          debugPrint("Fila: Falha ao enviar ID $id (Internet offline?). Erro: $e");
          
          await _db!.update(
            'fila_eventos', 
            {'tentativas': (item['tentativas'] as int) + 1},
            where: 'id = ?', 
            whereArgs: [id]
          );
          // Interrompe o loop atual para tentar novamente no próximo ciclo do Timer
          break; 
        }
      }
    } catch (e) {
      debugPrint("Fila: Erro crítico no processamento: $e");
    } finally {
      _isSyncing = false;
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
              debugPrint('DIO: Token expirado, tentando refresh...');
              final response = await _supabase.auth.refreshSession();
              final newToken = response.session?.accessToken;
              if (newToken != null) {
                options.headers['Authorization'] = 'Bearer $newToken';
              }
            } else {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            debugPrint('DIO ERROR: Token inválido ou expirado (401)');
          }
          return handler.next(e);
        },
      ),
    );
  }

  // --- MÉTODOS DE BUSCA (API) ---

  Future<List<dynamic>> buscarDadosPorAba(String aba) async {
    try {
      switch (aba) {
        case 'Jogos': return await listarTodasPartidas();
        case 'Árbitros': return await listarTodosArbitros();
        case 'Campeonatos': return await listarTodosCampeonatos();
        default: return [];
      }
    } catch (e) {
      debugPrint("Erro em buscarDadosPorAba: $e");
      return [];
    }
  }

  Future<List<Partida>> listarTodasPartidas() async {
    try {
      final response = await _dio.get('/partidas');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((m) => Partida.fromMap(m)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Erro ao buscar partidas: ${e.message}');
      return [];
    }
  }

  Future<List<Arbitro>> listarTodosArbitros() async {
    try {
      final response = await _dio.get('/arbitros');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((m) => Arbitro.fromMap(m)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Erro ao buscar árbitros: ${e.message}');
      return [];
    }
  }

  Future<List<Campeonato>> listarTodosCampeonatos() async {
    try {
      final response = await _dio.get('/campeonatos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((m) => Campeonato.fromMap(m)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Erro ao buscar campeonatos: ${e.message}');
      return [];
    }
  }

  Future<List<Partida>> listarPartidasMinhas() async {
    try {
      final response = await _dio.get('/partidas/minhas');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((m) => Partida.fromMap(m)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar minhas partidas: $e');
      return [];
    }
  }

  // --- MÉTODOS DE ESCRITA (COM SUPORTE OFFLINE) ---

  /// Salva o evento primeiro no Banco Local e dispara a tentativa de envio
  Future<void> salvarEvento({
    required String partidaId,
    required String tipoEventoId,
    String? equipeId,
    String? atletaId,
    String? atletaSaiId,
    required int tempoFormatado,
    String? descricao,
    bool isSubstitution = false,
  }) async {
    final Map<String, dynamic> payload = {
      'partida_id': partidaId,
      'tipo_evento_id': tipoEventoId,
      'equipe_id': equipeId,
      'atleta_id': atletaId,
      'atleta_sai_id': atletaSaiId,
      'tempo_cronometro': tempoFormatado,
      'descricao_detalhada': descricao,
      'is_substitution': isSubstitution,
      'criado_em': DateTime.now().toIso8601String(),
    };

    try {
      if (_db != null) {
        await _db!.insert('fila_eventos', {
          'dados': jsonEncode(payload),
          'tentativas': 0,
          'criado_em': payload['criado_em']
        });
        debugPrint("Sucesso: Evento registrado localmente.");
        
        // Tenta processar a fila imediatamente
        _processarFilaOffline();
      } else {
        // Fallback caso o banco falhe por algum motivo bizarro
        await _supabase.from('eventos_partida').insert(payload);
      }
    } catch (e) {
      debugPrint("Erro ao salvar evento (Cache ou Supabase): $e");
      rethrow;
    }
  }

  Future<void> atualizarPartida(
    String partidaId, {
    String? novoStatus,
    int? golsA,
    int? golsB,
  }) async {
    final Map<String, dynamic> dadosParaAtualizar = {};
    if (novoStatus != null) dadosParaAtualizar['status'] = novoStatus;
    if (golsA != null) dadosParaAtualizar['placar_a'] = golsA;
    if (golsB != null) dadosParaAtualizar['placar_b'] = golsB;

    if (dadosParaAtualizar.isNotEmpty) {
      await _supabase.from('partidas').update(dadosParaAtualizar).eq('id', partidaId);
    }
  }

  // --- OUTRAS BUSCAS ---

  Future<List<TipoEventoEsporte>> buscarTiposDeEventoDaPartida(String modalidadeId) async {
    try {
      final responseModalidade = await _dio.get('/modalidades/$modalidadeId');
      if (responseModalidade.statusCode == 200) {
        final String? esporteId = responseModalidade.data['esporteId'];
        if (esporteId == null) return [];

        final responseEventos = await _dio.get('/esportes/$esporteId/tipos-eventos');
        if (responseEventos.statusCode == 200) {
          final List<dynamic> data = responseEventos.data;
          return data.map((e) => TipoEventoEsporte.fromMap(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar tipos de evento: $e');
      return [];
    }
  }

  Future<List<dynamic>> buscarInscritos(String equipeId) async {
    try {
      final response = await _dio.get('/equipes/$equipeId/inscritos');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar inscritos: $e');
      return [];
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}