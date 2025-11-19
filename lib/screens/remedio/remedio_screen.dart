import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class RemedioScreen extends StatefulWidget {
  const RemedioScreen({super.key});
  @override
  State<RemedioScreen> createState() => _RemedioScreenState();
}

class _RemedioScreenState extends State<RemedioScreen> {
  DateTime data = DateTime.now();
  String? tipo; // Insulina | Medicação oral
  final nome = TextEditingController();
  final dosagem = TextEditingController();

  final List<Map<String, String>> medicamentosComuns = [
    {'nome': 'Metformina', 'dosagem': '850 mg'},
    {'nome': 'Glibenclamida', 'dosagem': '5 mg'},
    {'nome': 'Insulina NPH', 'dosagem': '10 UI'},
    {'nome': 'Insulina Regular', 'dosagem': '8 UI'},
    {'nome': 'Losartana', 'dosagem': '50 mg'},
    {'nome': 'Hidroclorotiazida', 'dosagem': '25 mg'},
    {'nome': 'Sinvastatina', 'dosagem': '20 mg'},
    {'nome': 'Enalapril', 'dosagem': '10 mg'},
    {'nome': 'AAS', 'dosagem': '100 mg'},
    {'nome': 'Paracetamol', 'dosagem': '500 mg'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Data de consumo:', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _boxed(Row(children: [
            Expanded(child: Text(_fmt(data), style: const TextStyle(fontSize: 18))),
            IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: data);
              if (d == null) return;
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(data));
              setState(()=> data = DateTime(d.year,d.month,d.day,t!.hour,t.minute));
            })
          ])),
          const SizedBox(height: 10),

          _boxed(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tipo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            RadioListTile(value: 'Insulina', groupValue: tipo, onChanged: (v)=> setState(()=> tipo=v), title: const Text('Insulina')),
            RadioListTile(value: 'Medicação oral', groupValue: tipo, onChanged: (v)=> setState(()=> tipo=v), title: const Text('Medicação oral')),
          ])),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _boxed(
                  Autocomplete<Map<String, String>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, String>>.empty();
                      }
                      return medicamentosComuns.where((med) => 
                        med['nome']!.toLowerCase().contains(textEditingValue.text.toLowerCase())
                      );
                    },
                    displayStringForOption: (opt) => opt['nome']!,
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nome do medicamento',
                        ),
                      );
                    },
                    onSelected: (Map<String, String> medicamento) {
                      nome.text = medicamento['nome']!;
                      dosagem.text = medicamento['dosagem']!;
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: options.map((opt) {
                              return ListTile(
                                title: Text(opt['nome']!),
                                subtitle: Text(opt['dosagem']!),
                                onTap: () => onSelected(opt),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _boxed(TextField(
                  controller: dosagem,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Dosagem (unidades/mg)',
                  ),
                )),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _bigButton('Enviar', () async {
            final auth = context.read<AuthService>();
            final fs = context.read<FirestoreService>();

            if (nome.text.trim().isEmpty || dosagem.text.trim().isEmpty || tipo == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preencha todos os campos antes de salvar.')),
              );
              return;
            }

            await fs.remedios(auth.user!.uid).add({
              'data': Timestamp.fromDate(data),
              'tipo': tipo,
              'nome': nome.text.trim(),
              'dosagem': dosagem.text.trim(),
            });

            nome.clear();
            dosagem.clear();
            tipo = null;
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicação salva com sucesso!')));
          }),
        ],
      ),
    );
  }

  Widget _boxed(Widget child) => Container(
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
