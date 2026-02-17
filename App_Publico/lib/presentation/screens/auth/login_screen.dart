import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_input_label.dart';
import '../../widgets/auth/auth_input_field.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_feedback_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final remember = prefs.getBool('remember_me') ?? false;
    if (remember && savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() => _remember = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CAPTURANDO AS DIMENSÕES DA TELA PARA RESPONSIVIDADE
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 393;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Fundo com Gradiente
            const GradientBackground(),
          // Conteúdo Principal
          Column(
            children: [
          // --- TOPO (DINÂMICO) ---
          AuthHeader(isSmall: isSmallScreen),

            // --- CORPO (DINÂMICO) ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  // Redução gradual de padding lateral
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 24 : 32, 
                    isSmallScreen ? 30 : 45, 
                    isSmallScreen ? 24 : 32, 
                    20
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 28 : 34,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 25 : 35),
                      
                      const AuthInputLabel(label: 'Seu e-mail:'),
                      AuthInputField(
                        controller: _emailController,
                        placeholder: 'exemplo@email.com',
                        svgAsset: 'assets/images/envelope.svg',
                        keyboardType: TextInputType.emailAddress,
                        isSmall: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 15 : 25),
                      
                      const AuthInputLabel(label: 'Sua senha:'),
                      AuthInputField(
                        controller: _passwordController,
                        placeholder: '••••••••',
                        svgAsset: 'assets/images/key.svg',
                        obscureText: true,
                        isSmall: isSmallScreen,
                      ),
                      
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 20, width: 20,
                                child: Checkbox(
                                  value: _remember,
                                  onChanged: (val) => setState(() => _remember = val ?? false),
                                  activeColor: const Color(0xFFF85C39),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lembrar',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: isSmallScreen ? 12 : 13, color: Colors.black54),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'Esqueci a senha',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: isSmallScreen ? 12 : 13, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      
                      // Mensagens de Feedback
                      AuthFeedbackMessage(
                        errorMessage: _error,
                        successMessage: _success,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 25 : 35),
                      
                      AuthButton(
                        text: 'Entrar',
                        onPressed: _login,
                        isLoading: _loading,
                        isSmall: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 20 : 25),
                      
                      Center(
                        child: SizedBox(
                          width: 260,
                          child: Text(
                            'Não tem conta ainda? Solicite ao administrador',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isSmallScreen ? 11 : 12,
                               // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.5),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE AUTENTICAÇÃO ---

  Future<void> _login() async {
    // Normalização dos dados para evitar erros de teclado no celular físico
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Preencha todos os campos");
      return;
    }
    
    setState(() { _loading = true; _error = null; });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        if (_remember) {
          await prefs.setString('saved_email', email);
          await prefs.setString('saved_password', password);
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.clear();
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      // Diferencia erro de rede de erro de credencial
      setState(() => _error = e.message.contains("network") ? "Sem conexão com a internet" : "E-mail ou senha incorretos");
    } catch (e) {
      setState(() => _error = "Erro de conexão. Verifique sua internet.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _error = "Digite seu e-mail primeiro");
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email, redirectTo: 'apparbitro://reset-password');
      setState(() { _success = "E-mail de recuperação enviado!"; _error = null; });
    } catch (e) {
      setState(() { _error = "Erro ao enviar e-mail"; _success = null; });
    }
  }
}