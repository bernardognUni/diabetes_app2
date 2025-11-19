import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notifications_service.dart';

class AlertsFormScreen extends StatefulWidget {
  const AlertsFormScreen({super.key});
  @override
  State<AlertsFormScreen> createState() => _AlertsFormScreenState();
}

class _AlertsFormScreenState extends State<AlertsFormScreen> {
  DateTime when = DateTime.now().add(const Duration(minutes: 1));
  String? lembrete; // Café, Almoço, Lanche, Jantar, Extra
  final medicamento = TextEditingController(text: 'Dipirona 5mg');
  bool sound = true, vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas e Lembretes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 8),
          const Text('Data de consumo:', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _boxed(Row(children: [
            Expanded(child: Text('${when.day.toString().padLeft(2,'0')}/${when.month.toString().padLeft(2,'0')}/${when.year}, ${when.hour.toString().padLeft(2,'0')}:${when.minute.toString().padLeft(2,'0')}',
              style: const TextStyle(fontSize: 18))),
            IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: when);
              if (d == null) return;
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(when));
              setState(()=> when = DateTime(d.year,d.month,d.day,t!.hour,t.minute));
            })
          ])),
          const SizedBox(height: 12),

          _boxed(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Lembretes de Medição:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ...['Café da manhã','Almoço','Lanche','Jantar','Extra']
              .map((e)=> RadioListTile(value: e, groupValue: lembrete, onChanged: (v)=> setState(()=>lembrete=v), title: Text(e)))
          ])),
          const SizedBox(height: 10),
          _boxed(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Medicamento:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(controller: medicamento, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Dipirona 5mg')),
          ])),
          const SizedBox(height: 10),
          _boxed(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Notificação:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            CheckboxListTile(value: sound, onChanged: (v)=> setState(()=> sound = v!), title: const Text('Som')),
            CheckboxListTile(value: vibration, onChanged: (v)=> setState(()=> vibration = v!), title: const Text('Vibração')),
          ])),
          const SizedBox(height: 16),
          PrimaryButton(text: 'Adicionar Alerta', onTap: () async {
            final auth = context.read<AuthService>();
            final fs = context.read<FirestoreService>();
            final doc = await fs.alertas(auth.user!.uid).add({
              'data': when,
              'titulo': lembrete ?? 'Lembrete',
              'descricao': medicamento.text.trim(),
              'canal': sound ? 'som' : 'silencioso',
              'vibracao': vibration,
              'ativo': true,
              'cor': 'blue',
            });
            await NotificationsService().schedule(
              id: doc.id.hashCode,
              when: when,
              title: lembrete ?? 'Lembrete',
              body: 'Hora: ${medicamento.text.trim()}',
              sound: sound,
              vibration: vibration,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta adicionado!')));
          }),
        ]),
      ),
    );
  }

  Widget _boxed(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(16)),
    child: child,
  );
}
