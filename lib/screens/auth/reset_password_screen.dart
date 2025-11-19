import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
//import 'register_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7EC3FF),
      appBar: AppBar(title: const Text('Recuperação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          const Text('Digite o e-mail cadastrado para receber um link de recuperação de senha',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          InputField(hint: 'e-mail', controller: email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 18),
          PrimaryButton(text: 'Enviar', onTap: () async {
            try {
              await context.read<AuthService>().resetPassword(email.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail enviado!')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
            }
          }),
          const SizedBox(height: 12),
          PrimaryButton(text: 'Cadastrar-se', color: const Color(0xFF6C8EFF),
            onTap: () => Navigator.pop(context),
          ),
        ]),
      ),
    );
  }
}
