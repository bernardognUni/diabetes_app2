import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class MedirScreen extends StatefulWidget {
  const MedirScreen({super.key});
  @override
  State<MedirScreen> createState() => _MedirScreenState();
}

class _MedirScreenState extends State<MedirScreen> {
  DateTime data = DateTime.now();
  String? contexto; // Jejum | 2h pos refeicao | Antes de dormir | Outro
  final valorCtrl = TextEditingController();
  final obsCtrl = TextEditingController();
  final outroCtrl = TextEditingController();
  DateTime? ultimaRefeicao;

  @override
  void dispose() {
    valorCtrl.dispose();
    obsCtrl.dispose();
    outroCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _boxed(Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();

    Future<void> pickDate() async {
      final d = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: data,
      );
      if (d == null) return;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(data),
      );
      if (t == null) return;
      setState(() => data = DateTime(d.year, d.month, d.day, t.hour, t.minute));
    }

    Future<void> pickUltimaRefeicao() async {
      final base = ultimaRefeicao ?? DateTime.now();
      final d = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: base,
      );
      if (d == null) return;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(base),
      );
      if (t == null) return;
      setState(
        () =>
            ultimaRefeicao = DateTime(d.year, d.month, d.day, t.hour, t.minute),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Data de medição:',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _boxed(
            Row(
              children: [
                Expanded(
                  child: Text(_fmt(data), style: const TextStyle(fontSize: 18)),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: pickDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _boxed(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta medição é:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                ...['Jejum', '2h pos refeicao', 'Antes de dormir', 'Outro'].map(
                  (opt) => RadioListTile<String>(
                    value: opt,
                    groupValue: contexto,
                    onChanged: (v) => setState(() => contexto = v),
                    title: Text(
                      {
                        'Jejum': 'Em jejum',
                        '2h pos refeicao': '2h após refeição',
                        'Antes de dormir': 'Antes de dormir',
                        'Outro': 'Outro momento',
                      }[opt]!,
                    ),
                  ),
                ),
                if (contexto == 'Outro')
                  TextField(
                    controller: outroCtrl,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Descreva o momento (ex.: durante exercício)',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _boxed(
            Row(
              children: [
                const Text(
                  'Valor:  ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: valorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'mg/dL',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _boxed(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Última refeição (opcional):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ultimaRefeicao == null ? '—' : _fmt(ultimaRefeicao!),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: pickUltimaRefeicao,
                      icon: const Icon(Icons.schedule),
                      label: const Text('Selecionar'),
                    ),
                    if (ultimaRefeicao != null)
                      IconButton(
                        onPressed: () => setState(() => ultimaRefeicao = null),
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _boxed(
            TextField(
              controller: obsCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Observações',
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D43FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36),
                ),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: () async {
                final v = int.tryParse(valorCtrl.text.trim());
                if (v == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe um valor válido')),
                  );
                  return;
                }
                if (contexto == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecione o contexto da medição'),
                    ),
                  );
                  return;
                }
                final auth = context.read<AuthService>();
                final fs = context.read<FirestoreService>();
                await fs.medicoes(auth.user!.uid).add({
                  'data': Timestamp.fromDate(data),
                  'valor': v,
                  'contexto': contexto,
                  'contextoOutro': (contexto == 'Outro'
                      ? outroCtrl.text.trim()
                      : null),
                  'ultimaRefeicao': ultimaRefeicao == null
                      ? null
                      : Timestamp.fromDate(ultimaRefeicao!),
                  'observacoes': obsCtrl.text.trim(),
                });

                valorCtrl.clear();
                obsCtrl.clear();
                outroCtrl.clear();
                ultimaRefeicao = null;
                setState(() => contexto = null);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medição registrada')),
                );
              },
              child: const Text('Enviar'),
            ),
          ),
        ],
      ),
    );
  }
}
