import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ExportacaoScreen extends StatefulWidget {
  const ExportacaoScreen({super.key});
  @override
  State<ExportacaoScreen> createState() => _ExportacaoScreenState();
}

class _ExportacaoScreenState extends State<ExportacaoScreen> {
  String? periodo; // semana|mes|3meses|custom|extra
  String? formato; // PDF|CSV
  final selecionados = <String>{}; // medicoes, refeicoes, medicacoes, observacoes, graficos
  DateTimeRange? customRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Exportar Dados:', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Selecionar período:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ...[
              'Última semana','Último mês','Últimos 3 meses','Período personalizado','Extra'
            ].map((e)=> RadioListTile(value: e, groupValue: periodo, onChanged: (v) async {
              periodo = v;
              if (v == 'Período personalizado') {
                final now = DateTime.now();
                customRange = await showDateRangePicker(context: context, firstDate: DateTime(now.year-2), lastDate: DateTime(now.year+1), initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now));
              }
              setState(() {});
            }, title: Text(e))),
          ])),
          const SizedBox(height: 10),
          _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Formato:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            RadioListTile(value: 'PDF (para profissionais)', groupValue: formato, onChanged: (v)=> setState(()=> formato=v), title: const Text('PDF (para profissionais)')),
            RadioListTile(value: 'CSV (planilha)', groupValue: formato, onChanged: (v)=> setState(()=> formato=v), title: const Text('CSV (planilha)')),
          ])),
          const SizedBox(height: 10),
          _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Conteúdos:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ...['Medições de glicemia','Refeições','Medicações','Observações','Gráficos'].map((e){
              final key = e.toLowerCase();
              return CheckboxListTile(
                value: selecionados.contains(key),
                onChanged: (v){ setState(()=> v! ? selecionados.add(key) : selecionados.remove(key)); },
                title: Text(e),
              );
            }),
          ])),
          const SizedBox(height: 16),
          _bigButton('Gerar arquivo', () async {
            if (formato?.startsWith('CSV') != true) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Neste protótipo, exporto CSV.')));
              return;
            }
            if (!selecionados.contains('medições de glicemia')) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione "Medições de glicemia" para exportar.')));
              return;
            }
            final file = await _exportCsvMedicoes(context);
            await Share.shareXFiles([XFile(file.path)], text: 'Exportação Diabetes APP');
          }),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Future<File> _exportCsvMedicoes(BuildContext context) async {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    Query q = fs.medicoes(auth.user!.uid).orderBy('data', descending: false);
    final now = DateTime.now();
    DateTime start = now.subtract(const Duration(days: 7));
    DateTime end = now;

    switch (periodo) {
      case 'Última semana': start = now.subtract(const Duration(days: 7)); break;
      case 'Último mês': start = DateTime(now.year, now.month-1, now.day); break;
      case 'Últimos 3 meses': start = DateTime(now.year, now.month-3, now.day); break;
      case 'Período personalizado':
        if (customRange != null) { start = customRange!.start; end = customRange!.end; }
        break;
      default: break;
    }
    q = q.where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
         .where('data', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final snap = await q.get();
    final rows = <List<dynamic>>[
      ['Data','Hora','Valor (mg/dL)','Contexto','Observações']
    ];
    for (final d in snap.docs) {
      final m = d.data() as Map<String,dynamic>;
      final dt = (m['data'] as Timestamp).toDate();
      rows.add([
        '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}',
        '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}',
        m['valor'],
        m['contexto'] ?? '',
        m['obs'] ?? '',
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/export_medicoes.csv');
    await file.writeAsString(csv);
    return file;
  }

  Widget _box(Widget child) => Container(
    width: double.infinity, padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(16)),
    child: child,
  );
  Widget _bigButton(String text, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 70,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D43FF), foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      onPressed: onTap, child: Text(text),
    ),
  );
}
