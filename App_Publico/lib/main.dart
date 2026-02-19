import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Imports das suas telas
import 'presentation/screens/main/home_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/main/perfil_screen.dart';
import 'presentation/screens/main/arbitros_screen.dart';
import 'presentation/screens/main/campeonatos_screen.dart';
import 'presentation/screens/main/configuracoes_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // 1. Garante a inicialização dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o Supabase ANTES de qualquer outra coisa
  await Supabase.initialize(
    url: 'https://hlgnackuzfhkhloemtey.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZ25hY2t1emZoa2hsb2VtdGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjUyNzIsImV4cCI6MjA4NjIwMTI3Mn0.8jq8Anq419bzO94DqCrCcNAJSOsiqGQ8UiFsEO6ibH4',
  );

  // 3. Inicializa a localização para datas (pt_BR)
  await initializeDateFormatting('pt_BR', null);

  // 4. Escuta mudanças de autenticação (Recuperação de senha)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/reset-password', (route) => false);
    }
  });

  // 5. Roda o app apenas UMA vez
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/arbitros': (context) => const ArbitrosScreen(),
        '/campeonatos': (context) => const CampeonatosScreen(),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
      },
    );
  }
}