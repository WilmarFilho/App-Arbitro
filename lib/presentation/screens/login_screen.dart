import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Se já está logado, vai direto para home
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/home');
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
      setState(() {
        _remember = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Estende o corpo para baixo da barra de status
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -0.6), // Foco do brilho no topo
            radius: 1.3,
            colors: [
              Color.fromARGB(255, 160, 255, 228),
              Color.fromARGB(255, 232, 255, 209),
              Color.fromARGB(255, 204, 255, 240),
            ],
            stops: [0.0, 0.54, 1.0],
          ),
        ),
        child: Column(
          children: [
            // --- TOPO: LOGO E TÍTULO (Fundo Gradiente) ---
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/meteor.svg',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'KYAREM EVENTOS',
                      style: TextStyle(
                        fontFamily: 'Bebas Neue', // Verifique se o nome no pubspec é este
                        fontWeight: FontWeight.w400,
                        fontSize: 52,
                        color: Colors.black,
                        height: 1.0, 
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Área Administrativa',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Color.fromRGBO(0, 0, 0, 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // --- CORPO: PAINEL BRANCO ARREDONDADO ---
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
                  padding: const EdgeInsets.fromLTRB(32, 45, 32, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 34,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 35),
                      
                      // Email
                      _buildInputLabel('Seu e-mail:'),
                      _buildFigmaInput(
                        controller: _emailController,
                        placeholder: 'exemplo@email.com',
                        svgAsset: 'assets/images/envelope.svg',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Senha
                      _buildInputLabel('Sua senha:'),
                      _buildFigmaInput(
                        controller: _passwordController,
                        placeholder: '••••••••',
                        svgAsset: 'assets/images/key.svg',
                        obscureText: true,
                      ),
                      
                      const SizedBox(height: 15),

                      // Checkbox e Esqueci Senha
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _remember,
                                  onChanged: (val) => setState(() => _remember = val ?? false),
                                  activeColor: const Color(0xFFF85C39),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Lembrar senha',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _resetPassword,
                            child: const Text(
                              'Esqueci minha senha',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_error != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                        ),
                      ],

                      if (_success != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_success!, style: const TextStyle(color: Colors.green, fontSize: 14)),
                        ),
                      ],
                      
                      const SizedBox(height: 35),
                      
                      // Botão Entrar
                      _buildFigmaLoginButton(),
                      
                      const SizedBox(height: 25),
                      
                      // Texto de Rodapé
                      Center(
                        child: SizedBox(
                          width: 260,
                          child: Text(
                            'Não tem conta ainda? Solicite a criação com o administrador do sistema',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
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
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildFigmaInput({
    required TextEditingController controller,
    required String placeholder,
    required String svgAsset,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SvgPicture.asset(
              svgAsset, 
              width: 22, 
              height: 22, 
              colorFilter: ColorFilter.mode(
                const Color(0xFFF85C39).withOpacity(0.6), 
                BlendMode.srcIn,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              cursorColor: const Color(0xFFF85C39),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.2), fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(right: 16),
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF85C39),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Entrar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _error = "Preencha todos os campos";
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user != null && mounted) {
        // Salvar ou limpar credenciais conforme o checkbox
        final prefs = await SharedPreferences.getInstance();
        if (_remember) {
          await prefs.setString('saved_email', _emailController.text.trim());
          await prefs.setString('saved_password', _passwordController.text.trim());
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
          await prefs.setBool('remember_me', false);
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _error = "E-mail ou senha incorretos");
      }
    } on AuthException {
      setState(() => _error = "E-mail ou senha incorretos");
    } catch (e) {
      setState(() => _error = "Erro inesperado: Tente novamente");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = "Digite seu e-mail primeiro");
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'apparbitro://reset-password',
      );
      setState(() {
        _success = "E-mail de recuperação enviado!";
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = "Erro ao enviar e-mail";
        _success = null;
      });
    }
  }
}