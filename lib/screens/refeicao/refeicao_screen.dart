import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class RefeicaoScreen extends StatefulWidget {
  const RefeicaoScreen({super.key});
  @override
  State<RefeicaoScreen> createState() => _RefeicaoScreenState();
}

class _RefeicaoScreenState extends State<RefeicaoScreen> {
  DateTime data = DateTime.now();
  String? tipo;
  final desc = TextEditingController();
  final carbs = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Data de consumo:',
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
                  onPressed: () async {
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
                    setState(
                      () => data = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t!.hour,
                        t.minute,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _boxed(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de refeição:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                ...['Café da manhã', 'Almoço', 'Lanche', 'Jantar', 'Extra'].map(
                  (e) => RadioListTile(
                    value: e,
                    groupValue: tipo,
                    onChanged: (v) => setState(() => tipo = v),
                    title: Text(e),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _boxed(
            SizedBox(
              height: 140,
              child: TextField(
                controller: desc,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Descrição do que comeu',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _boxed(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opcional:',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: carbs,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Carboidratos (g): _____',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _bigButton('Enviar', () async {
            final auth = context.read<AuthService>();
            final fs = context.read<FirestoreService>();
            await fs.refeicoes(auth.user!.uid).add({
              'data': Timestamp.fromDate(data),
              'tipo': tipo,
              'descricao': desc.text.trim(),
              'carboidratos': double.tryParse(carbs.text.trim()),
            });
            desc.clear();
            carbs.clear();
            tipo = null;
            setState(() {});
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Refeição salva!')));
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _boxed(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _bigButton(String text, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 64,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D43FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
      onPressed: onTap,
      child: Text(text),
    ),
  );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
