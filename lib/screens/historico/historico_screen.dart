import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final df = DateFormat('dd/MM/yyyy – HH:mm');

    return StreamBuilder<QuerySnapshot>(
      stream: fs.medicoes(auth.user!.uid).orderBy('data', descending: true).snapshots(),
      builder: (c, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Sem medições ainda.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final d = docs[i].data()! as Map<String, dynamic>;
            final dt = (d['data'] as Timestamp).toDate();
            final valor = d['valor'] ?? 0;
            final obs = d['observacoes'] ?? '';
            final contexto = d['contexto'] ?? '';

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  '${df.format(dt)}  ${valor} mg/dL',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  [
                    if (contexto.isNotEmpty) 'Contexto: $contexto',
                    if (obs.isNotEmpty) 'Obs: $obs'
                  ].join('\n'),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: () => _editarMedicao(context, docs[i].reference, d),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => docs[i].reference.delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editarMedicao(BuildContext context, DocumentReference ref, Map<String, dynamic> dados) {
    final valorCtrl = TextEditingController(text: dados['valor']?.toString() ?? '');
    final obsCtrl = TextEditingController(text: dados['observacoes'] ?? '');
    String? contexto = dados['contexto'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Medição'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Valor (mg/dL):'),
              const SizedBox(height: 4),
              TextField(
                controller: valorCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 110',
                ),
              ),
              const SizedBox(height: 12),

              const Text('Contexto:'),
              const SizedBox(height: 4),
              Column(
                children: [
                  RadioListTile(
                    value: 'Jejum',
                    groupValue: contexto,
                    title: const Text('Em jejum'),
                    onChanged: (v) => contexto = v,
                  ),
                  RadioListTile(
                    value: '2h pos refeicao',
                    groupValue: contexto,
                    title: const Text('2h após refeição'),
                    onChanged: (v) => contexto = v,
                  ),
                  RadioListTile(
                    value: 'Antes de dormir',
                    groupValue: contexto,
                    title: const Text('Antes de dormir'),
                    onChanged: (v) => contexto = v,
                  ),
                  RadioListTile(
                    value: 'Outro',
                    groupValue: contexto,
                    title: const Text('Outro'),
                    onChanged: (v) => contexto = v,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Text('Observações:'),
              const SizedBox(height: 4),
              TextField(
                controller: obsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: medições após caminhada...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D43FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final valorNovo = int.tryParse(valorCtrl.text.trim());
              if (valorNovo == null || valorNovo <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insira um valor válido de glicemia')),
                );
                return;
              }

              await ref.update({
                'valor': valorNovo,
                'contexto': contexto,
                'observacoes': obsCtrl.text.trim(),
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medição atualizada com sucesso!')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
