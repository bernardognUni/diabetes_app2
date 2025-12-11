import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final senha = TextEditingController();
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7EC3FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Image.asset('assets/imgs/robot.png', width: 220),
              const SizedBox(height: 12), //adicionar ideia da Profa. Letícia de colocar um balão de texto como se fosse uma fala do robô(logo)
              //                            e um tutorial do app ao entrar pelas primeiras vezes.
              const Text('Diabetes Tracker', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 24),
              InputField(hint: 'e-mail ou CPF', controller: email),
              const SizedBox(height: 12),
              InputField(
                hint: 'senha',
                controller: senha,
                obscure: hide,
                suffix: IconButton(
                  onPressed: () => setState(() => hide = !hide),
                  icon: Icon(hide ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(text: 'Entrar', onTap: () async {
                try {
                  await context.read<AuthService>().signIn(email.text.trim(), senha.text.trim());
                  if (!mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              }),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'Cadastrar-se',
                color: const Color(0xFF6C8EFF),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen())),
                child: const Text('Esqueci minha senha', style: TextStyle(decoration: TextDecoration.underline, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
