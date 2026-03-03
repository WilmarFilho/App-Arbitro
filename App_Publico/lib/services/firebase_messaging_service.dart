import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Lida com mensagens em segundo plano
  debugPrint('Handling a background message: ${message.messageId}');
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. Solicitar permissões (especialmente para iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Usuário concedeu permissão para notificações.');
    } else {
      debugPrint('Usuário não concedeu permissão para notificações.');
    }

    // 2. Configurar o handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Configurar o handler de foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Recebeu uma mensagem em foreground: ${message.messageId}');

      if (message.notification != null) {
        // Exibir usando o flutter_local_notifications existente
        NotificationService.instance.showPartidaEvento(
          id: message.hashCode & 0x7FFFFFFF,
          title: message.notification?.title ?? 'Nova Notificação',
          body: message.notification?.body ?? '',
        );
      }
    });
  }

  // Método para se inscrever em um tópico de uma partida específica
  Future<void> subscribeToPartidaTopic(String partidaId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('partida_$partidaId');
      debugPrint('Inscrito no tópico: partida_$partidaId');
    } catch (e) {
      debugPrint('Erro ao se inscrever no tópico: $e');
    }
  }

  // Método para cancelar inscrição de um tópico
  Future<void> unsubscribeFromPartidaTopic(String partidaId) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('partida_$partidaId');
      debugPrint('Inscrição cancelada do tópico: partida_$partidaId');
    } catch (e) {
      debugPrint('Erro ao cancelar inscrição no tópico: $e');
    }
  }
}
