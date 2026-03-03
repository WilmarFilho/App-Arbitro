import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/notification_service.dart';
import 'services/live_partidas_notification_watcher.dart';
import 'services/firebase_messaging_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Imports das suas telas
import 'models/campeonato_model.dart';
import 'presentation/screens/main/home_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/main/perfil_screen.dart';
import 'presentation/screens/main/modalidades_screen.dart';
import 'presentation/screens/main/configuracoes_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // 1. Garante a inicialização dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Carrega variáveis do .env (ex: CAMPEONATO_ID)
  await dotenv.load(fileName: '.env');

  // Inicializa o Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa serviço de mensagens do Firebase
  await FirebaseMessagingService().initNotifications();

  // 3. Inicializa o Supabase ANTES de qualquer outra coisa
  await Supabase.initialize(
    url: 'https://hlgnackuzfhkhloemtey.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZ25hY2t1emZoa2hsb2VtdGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjUyNzIsImV4cCI6MjA4NjIwMTI3Mn0.8jq8Anq419bzO94DqCrCcNAJSOsiqGQ8UiFsEO6ibH4',
  );

  // 4. Inicializa a localização para datas (pt_BR)
  await initializeDateFormatting('pt_BR', null);

  // 5. Inicializa notificações locais
  await NotificationService.instance.init();

  // 6. Inicia watcher global de eventos ao vivo (notificação mesmo fora da tela do jogo)
  if (Supabase.instance.client.auth.currentSession != null) {
    await LivePartidasNotificationWatcher.instance.start();
  }

  // 7. Escuta mudanças de autenticação (Recuperação de senha + start/stop watcher)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/reset-password',
        (route) => false,
      );
    }

    if (data.event == AuthChangeEvent.signedIn ||
        data.event == AuthChangeEvent.tokenRefreshed) {
      LivePartidasNotificationWatcher.instance.start();
    } else if (data.event == AuthChangeEvent.signedOut) {
      LivePartidasNotificationWatcher.instance.stop();
    }
  });

  // 8. Roda o app apenas UMA vez
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LivePartidasNotificationWatcher.instance.refreshNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se existe uma sessão ativa para decidir a tela inicial
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Kyarem Eventos Público',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF85C39), // Usei a cor do seu botão
        ),
        fontFamily: 'Poppins', // Define Poppins como padrão para o app
      ),
      // Se tiver sessão vai para Home, se não, para Login
      initialRoute: session != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/modalidades': (context) => ModalidadesScreen(
          campeonato: Campeonato(
            id: dotenv.get('CAMPEONATO_ID'),
            nome: dotenv.get('CAMPEONATO_NOME', fallback: 'Campeonato'),
          ),
        ),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
      },
    );
  }
}
