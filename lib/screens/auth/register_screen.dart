//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nome = TextEditingController();
  final sobrenome = TextEditingController();
  final nomeMae = TextEditingController();
  final dataNasc = TextEditingController();
  final cpf = TextEditingController();
  final email = TextEditingController();
  final telefone = TextEditingController();
  final senha = TextEditingController();
  final confirmar = TextEditingController();
  bool senhaHide = true, confirmarHide = true;

  String? tipoDiabetes;
  String? nivel;
  String? genero;
  bool bsUtiliza = false;
  final bsNome = TextEditingController();

  // META GLICÊMICA calculada automaticamente
  int? metaMin;
  int? metaMax;

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final apenasLetras = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-ZÀ-ÿ\s]'),
  );

  @override
  void dispose() {
    nome.dispose();
    nomeMae.dispose();
    dataNasc.dispose();
    telefone.dispose();
    cpf.dispose();
    email.dispose();
    senha.dispose();
    confirmar.dispose();
    bsNome.dispose();
    super.dispose();
  }

  void atualizarMetas() {
    if (tipoDiabetes == null) return;
    if (dataNasc.text.length != 10) return;

    try {
      final p = dataNasc.text.split('/');
      final birthDate = DateTime(
        int.parse(p[2]),
        int.parse(p[1]),
        int.parse(p[0]),
      );

      final metas = calcularMetas(tipoDiabetes!, birthDate);

      setState(() {
        metaMin = metas['min'];
        metaMax = metas['max'];
      });
    } catch (_) {
      // Serve para ignorar erro de data incompleta
    }
  }

  Future<void> pickBirthDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: now,
    );

    if (d != null) {
      final formatted =
          '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
      setState(() => dataNasc.text = formatted);
      atualizarMetas(); // Serve para atualizar automaticamente as metas glicêmicas já dentro dessa tela (colocar todos os valores de acordo com as metas da SDB - Sociedade Brasileira de Diabetes)
    }
  }

  Map<String, int> calcularMetas(String tipoDiabetes, DateTime birthDate) {
    final hoje = DateTime.now();
    int idade = hoje.year - birthDate.year;

    if (hoje.month < birthDate.month ||
        (hoje.month == birthDate.month && hoje.day < birthDate.day)) {
      idade--;
    }

    if (tipoDiabetes == 'Gestacional') {
      return {'min': 70, 'max': 95};
    }

    if (idade >= 75) {
      return {'min': 100, 'max': 150};
    }

    if (idade < 18) {
      return {'min': 90, 'max': 150};
    }

    return {'min': 80, 'max': 130};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7EC3FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Cadastro Inicial',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              InputField(
                hint: 'Nome Completo',
                controller: nome,
                inputFormatters: [apenasLetras],
              ),
              const SizedBox(height: 10),

              InputField(
                hint: 'Nome da mãe',
                controller: nomeMae,
                inputFormatters: [apenasLetras],
              ),
              const SizedBox(height: 10),

              InputField(
                hint: 'Data de nascimento (dd/mm/aaaa)',
                controller: dataNasc,
                keyboardType: TextInputType.number,
                inputFormatters: [dataMask],
                onChanged: (_) => atualizarMetas(),
                suffix: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: pickBirthDate,
                ),
              ),
              const SizedBox(height: 10),

              InputField(
                hint: 'CPF (000.000.000-00)',
                controller: cpf,
                keyboardType: TextInputType.number,
                inputFormatters: [cpfMask],
              ),
              const SizedBox(height: 10),

              InputField(
                hint: 'Telefone (00) 00000-0000',
                controller: telefone,
                keyboardType: TextInputType.phone,
                inputFormatters: [telefoneMask],
              ),
              const SizedBox(height: 10),

              _boxed(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text( // o código do gênero é diferente por ser por seleção e não escrita igual os demais dados
                      'Gênero:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _radio(
                          'Feminino',
                          genero,
                          (v) => setState(() => genero = v),
                        ),
                        _radio(
                          'Masculino',
                          genero,
                          (v) => setState(() => genero = v),
                        ),
                        _radio(
                          'Outro/Prefere não informar',
                          genero,
                          (v) => setState(() => genero = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Tipo de diabetes:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _radio(
                          'Tipo 1',
                          tipoDiabetes,
                          (v) {
                            setState(() => tipoDiabetes = v);
                            atualizarMetas();
                          },
                        ),
                        _radio(
                          'Tipo 2',
                          tipoDiabetes,
                          (v) {
                            setState(() => tipoDiabetes = v);
                            atualizarMetas();
                          },
                        ),
                        _radio(
                          'Gestacional',
                          tipoDiabetes,
                          (v) {
                            setState(() => tipoDiabetes = v);
                            atualizarMetas();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Nível de conhecimento:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _radio('Básico', nivel, (v) => setState(() => nivel = v)),
                        _radio('Intermediário', nivel,
                            (v) => setState(() => nivel = v)),
                        _radio(
                            'Avançado', nivel, (v) => setState(() => nivel = v)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Checkbox(
                          value: bsUtiliza,
                          onChanged: (v) =>
                              setState(() => bsUtiliza = v ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            'Utiliza UBS/SIAB/Outro sistema de saúde?',
                          ),
                        ),
                      ],
                    ),
                    if (bsUtiliza)
                      InputField(
                        hint: 'Nome do UBS/Sistema', // aqui é interessante colocar um autocomplete igual ao dos medicamentos para as UBS existentes na cidade
                        controller: bsNome,
                        inputFormatters: [apenasLetras],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              InputField(
                hint: 'E-mail',
                controller: email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),

              InputField(
                hint: 'Senha',
                controller: senha,
                obscure: senhaHide,
                suffix: IconButton(
                  onPressed: () => setState(() => senhaHide = !senhaHide),
                  icon:
                      Icon(senhaHide ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 10),

              InputField(
                hint: 'Confirmar senha',
                controller: confirmar,
                obscure: confirmarHide,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => confirmarHide = !confirmarHide),
                  icon: Icon(
                      confirmarHide ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Meta glicemia jejum:',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),

              if (metaMin == null || metaMax == null)
                const Text(
                  'Preencha data de nascimento e tipo de diabetes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                )
              else
                Text(
                  '$metaMin – $metaMax mg/dL',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),

              const SizedBox(height: 14),

              PrimaryButton(
                text: 'Concluir Cadastro',
                onTap: () async {
                  if (senha.text != confirmar.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Senhas não conferem')),
                    );
                    return;
                  }

                  DateTime birthDate;
                  try {
                    final partes = dataNasc.text.split('/');
                    birthDate = DateTime(
                      int.parse(partes[2]),
                      int.parse(partes[1]),
                      int.parse(partes[0]),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data de nascimento inválida')),
                    );
                    return;
                  }

                  // Serve para o calculdo das metas glicemicas automaticamente
                  final metas = calcularMetas(tipoDiabetes ?? 'Tipo 2', birthDate);
                  final metaMinFinal = metas['min']!;
                  final metaMaxFinal = metas['max']!;

                  try {
                    await context.read<AuthService>().signUp(
                      email.text.trim(),
                      senha.text.trim(),
                    );
                    final auth = context.read<AuthService>();
                    final user = auth.user!;
                    final fs = context.read<FirestoreService>();

                    await user.updateDisplayName(nome.text.trim());

                    await fs.perfil(user.uid).set({
                      'nomeCompleto': nome.text.trim(),
                      'nomeMae': nomeMae.text.trim(),
                      'genero': genero ?? 'Outro/Prefere não informar',
                      'cpf': cpf.text.trim(),
                      'telefone': telefone.text.trim(),
                      'dataNascimento': dataNasc.text.trim(),
                      'tipoDiabetes': tipoDiabetes ?? 'Tipo 2',
                      'nivelConhecimento': nivel ?? 'Básico',
                      'bsUtiliza': bsUtiliza,
                      'bsNome': bsNome.text.trim(),
                      'metaJejumMin': metaMinFinal,
                      'metaJejumMax': metaMaxFinal,
                    });

                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Erro: $e')));
                  }
                },
              ),

              const SizedBox(height: 12),

              PrimaryButton(
                text: 'Já tenho uma conta',
                color: const Color(0xFF6C8EFF),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radio(
    String label,
    String? group,
    void Function(String?) onChanged,
  ) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(value: label, groupValue: group, onChanged: onChanged),
          Text(label),
        ],
      );

  Widget _boxed({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: child,
      );
}
