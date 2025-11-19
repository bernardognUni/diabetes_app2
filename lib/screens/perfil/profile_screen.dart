import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final doc = fs.perfil(auth.user!.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: doc.get(),
        builder: (c, s) {
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          final m = s.data!.data() ?? {};

          final nome = (m['nomeCompleto'] ?? '').toString().trim();
          final nomeMae = (m['nomeMae'] ?? 'Não informado').toString().trim();
          final genero = (m['genero'] ?? 'Outro/Prefere não informar')
              .toString();
          final telefone = (m['telefone'] ?? 'Não informado').toString();
          final tipoDiabetes = (m['tipoDiabetes'] ?? 'Tipo 2').toString();
          final nivel = (m['nivelConhecimento'] ?? 'Básico').toString();
          final bsUtiliza = (m['bsUtiliza'] ?? false) as bool;
          final bsNome = (m['bsNome'] ?? '').toString().trim();
          final metaMin = (m['metaJejumMin'] ?? 80).toString();
          final metaMax = (m['metaJejumMax'] ?? 180).toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 64,
                  backgroundImage: AssetImage('assets/imgs/robot.png'),
                ),
                const SizedBox(height: 12),
                Text(
                  nome.isEmpty ? 'Paciente' : nome,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                _boxed(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações do perfil:',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _row('Nome completo', nome),
                      _row('Nome da mãe', nomeMae),
                      _row('Gênero', genero),
                      _row('Telefone', telefone),
                      _row('Tipo de diabetes', tipoDiabetes),
                      _row('Nível de conhecimento', nivel),
                      _row('Utiliza UBS/SIAB?', bsUtiliza ? 'Sim' : 'Não'),
                      if (bsUtiliza) _row('Nome do sistema', bsNome),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _boxed(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Metas de Glicemia:',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _row('Meta mínima (jejum)', '$metaMin mg/dL'),
                      _row('Meta máxima (jejum)', '$metaMax mg/dL'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _bigBtn('Editar informações pessoais', () {
                  _editarInformacoes(context, doc, m);
                }),
                const SizedBox(height: 12),
                _bigBtn('Editar metas de glicemia', () {
                  _editarMetas(context, doc, metaMin, metaMax);
                }),
                const SizedBox(height: 12),
                _bigBtn('Alterar nível de conteúdo', () {
                  _alterarNivel(context, doc, nivel);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editarMetas(
    BuildContext context,
    DocumentReference doc,
    String metaMin,
    String metaMax,
  ) {
    final minCtrl = TextEditingController(text: metaMin);
    final maxCtrl = TextEditingController(text: metaMax);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar metas de glicemia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta mínima (mg/dL)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: maxCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta máxima (mg/dL)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Salvar'),
            onPressed: () async {
              await doc.update({
                'metaJejumMin': int.tryParse(minCtrl.text) ?? 80,
                'metaJejumMax': int.tryParse(maxCtrl.text) ?? 180,
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Metas atualizadas com sucesso!'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _editarInformacoes(
    BuildContext context,
    DocumentReference doc,
    Map<String, dynamic> m,
  ) {
    final nomeCtrl = TextEditingController(text: m['nomeCompleto']);
    final nomeMaeCtrl = TextEditingController(text: m['nomeMae']);
    String genero = m['genero'] ?? 'Outro/Prefere não informar';
    final telefoneCtrl = TextEditingController(text: m['telefone']);
    String tipo = m['tipoDiabetes'] ?? 'Tipo 2';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar informações pessoais'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome completo'),
              ),
              TextField(
                controller: nomeMaeCtrl,
                decoration: const InputDecoration(labelText: 'Nome da mãe'),
              ),
              TextField(
                controller: telefoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: genero,
                decoration: const InputDecoration(labelText: 'Gênero'),
                items: const [
                  DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                  DropdownMenuItem(
                    value: 'Masculino',
                    child: Text('Masculino'),
                  ),
                  DropdownMenuItem(
                    value: 'Outro/Prefere não informar',
                    child: Text('Outro/Prefere não informar'),
                  ),
                ],
                onChanged: (v) => genero = v ?? genero,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de diabetes',
                ),
                items: const [
                  DropdownMenuItem(value: 'Tipo 1', child: Text('Tipo 1')),
                  DropdownMenuItem(value: 'Tipo 2', child: Text('Tipo 2')),
                  DropdownMenuItem(
                    value: 'Gestacional',
                    child: Text('Gestacional'),
                  ),
                ],
                onChanged: (v) => tipo = v ?? tipo,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Salvar'),
            onPressed: () async {
              await doc.update({
                'nomeCompleto': nomeCtrl.text.trim(),
                'nomeMae': nomeMaeCtrl.text.trim(),
                'genero': genero,
                'tipoDiabetes': tipo,
                'telefone': telefoneCtrl.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informações atualizadas com sucesso!'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _alterarNivel(
    BuildContext context,
    DocumentReference doc,
    String nivelAtual,
  ) {
    String nivel = nivelAtual;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar nível de conteúdo'),
        content: DropdownButtonFormField<String>(
          value: nivel,
          items: const [
            DropdownMenuItem(value: 'Básico', child: Text('Básico')),
            DropdownMenuItem(
              value: 'Intermediário',
              child: Text('Intermediário'),
            ),
            DropdownMenuItem(value: 'Avançado', child: Text('Avançado')),
          ],
          onChanged: (v) => nivel = v ?? nivel,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await doc.update({'nivelConhecimento': nivel});
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nível de conteúdo atualizado!'),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 18),
        children: [
          TextSpan(
            text: '$k: ',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: v),
        ],
      ),
    ),
  );

  Widget _boxed(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black),
    ),
    child: child,
  );

  Widget _bigBtn(String t, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 64,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D43FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      child: Text(t),
    ),
  );
}
