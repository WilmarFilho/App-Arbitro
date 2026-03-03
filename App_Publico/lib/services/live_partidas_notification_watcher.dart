import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/partida_model.dart';
import 'evento_service.dart';
import 'notification_service.dart';
import 'partida_service.dart';

class LivePartidasNotificationWatcher {
  LivePartidasNotificationWatcher._();

  static final LivePartidasNotificationWatcher instance = LivePartidasNotificationWatcher._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final PartidaService _partidaService = PartidaService();
  final EventoService _eventoService = EventoService();

  StreamSubscription<List<Map<String, dynamic>>>? _eventosSub;
  Timer? _refreshTimer;

  bool _started = false;
  bool _starting = false;

  bool _eventosInicialCarregado = false;
  final Set<String> _eventosJaNotificados = <String>{};

  final Map<String, _PartidaInfo> _partidaInfoById = <String, _PartidaInfo>{};
  final Map<String, Map<String, String>> _tiposEventoPorModalidade = <String, Map<String, String>>{};

  Set<String> _currentPartidaIds = <String>{};

  bool get isRunning => _started;

  Future<void> start() async {
    if (_started || _starting) return;
    _starting = true;
    try {
      _started = true;
      await _refreshPartidasAndSubscription();

      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
        try {
          await _refreshPartidasAndSubscription();
        } catch (e) {
          debugPrint('LivePartidasNotificationWatcher refresh error: $e');
        }
      });
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    await _eventosSub?.cancel();
    _eventosSub = null;

    _eventosInicialCarregado = false;
    _eventosJaNotificados.clear();
    _partidaInfoById.clear();
    _currentPartidaIds = <String>{};

    _started = false;
  }

  Future<void> refreshNow() async {
    if (!_started) return;
    await _refreshPartidasAndSubscription(forceRestart: false);
  }

  Future<void> _refreshPartidasAndSubscription({bool forceRestart = false}) async {
    // Mantém o mesmo comportamento do app hoje: só notifica com sessão ativa.
    if (_supabase.auth.currentSession == null) return;

    final List<Partida> destaques = await _partidaService.listarPartidasDestaque();
    final Map<String, _PartidaInfo> newInfo = <String, _PartidaInfo>{};
    final Set<String> newIds = <String>{};

    for (final p in destaques) {
      newIds.add(p.id);
      newInfo[p.id] = _PartidaInfo(
        partidaId: p.id,
        modalidadeId: p.modalidadeId,
        timeA: p.equipeA?.nome ?? 'Time A',
        timeB: p.equipeB?.nome ?? 'Time B',
      );
    }

    // Atualiza caches
    _partidaInfoById
      ..clear()
      ..addAll(newInfo);

    // Pré-carrega tipos por modalidade (evita query por notificação)
    final Set<String> modalidades = newInfo.values.map((e) => e.modalidadeId).toSet();
    for (final modalidadeId in modalidades) {
      if (_tiposEventoPorModalidade.containsKey(modalidadeId)) continue;
      final tipos = await _eventoService.buscarTiposPorPartida(modalidadeId);
      _tiposEventoPorModalidade[modalidadeId] = {
        for (final t in tipos) (t['id']?.toString() ?? ''): (t['nome']?.toString() ?? 'Evento').trim(),
      }..removeWhere((k, _) => k.isEmpty);
    }

    final bool idsChanged = !setEquals(_currentPartidaIds, newIds);
    if (!forceRestart && !idsChanged) return;

    _currentPartidaIds = newIds;

    await _eventosSub?.cancel();
    _eventosSub = null;

    _eventosInicialCarregado = false;
    _eventosJaNotificados.clear();

    if (newIds.isEmpty) return;

    final eventosStream = _supabase
        .from('eventos_partida')
        .stream(primaryKey: ['id'])
        .inFilter('partida_id', newIds.toList())
        .order('criado_em', ascending: false);

    _eventosSub = eventosStream.listen(_handleEventosParaNotificacao);
  }

  Future<void> _handleEventosParaNotificacao(List<Map<String, dynamic>> eventos) async {
    if (_supabase.auth.currentSession == null) return;

    if (!_eventosInicialCarregado) {
      for (final ev in eventos) {
        final id = ev['id']?.toString();
        if (id != null) _eventosJaNotificados.add(id);
      }
      _eventosInicialCarregado = true;
      return;
    }

    if (eventos.isEmpty) return;

    for (final ev in eventos) {
      final idStr = ev['id']?.toString();
      if (idStr == null) continue;
      if (_eventosJaNotificados.contains(idStr)) continue;

      _eventosJaNotificados.add(idStr);

      final partidaId = ev['partida_id']?.toString();
      final info = partidaId != null ? _partidaInfoById[partidaId] : null;
      final modalidadeId = info?.modalidadeId;

      final tipoId = ev['tipo_evento_id']?.toString();
      final tipos = modalidadeId != null ? _tiposEventoPorModalidade[modalidadeId] : null;
      final tipoNome = (tipoId != null && tipos != null) ? (tipos[tipoId] ?? 'Evento') : 'Evento';

      final descricao = (ev['descricao_detalhada']?.toString() ?? '').trim();
      final title = info != null ? '${info.timeA} x ${info.timeB}' : 'Novo evento';
      final body = descricao.isNotEmpty ? '$tipoNome: $descricao' : tipoNome;

      final notifId = idStr.hashCode & 0x7fffffff;
      await NotificationService.instance.showPartidaEvento(id: notifId, title: title, body: body);
    }
  }
}

class _PartidaInfo {
  final String partidaId;
  final String modalidadeId;
  final String timeA;
  final String timeB;

  const _PartidaInfo({
    required this.partidaId,
    required this.modalidadeId,
    required this.timeA,
    required this.timeB,
  });
}

