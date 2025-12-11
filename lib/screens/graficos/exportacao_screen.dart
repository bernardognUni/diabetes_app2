import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

// é utilizado stateful para atualizar a tela quando seleciona período/formato/conteúdo(quando algo precisa ser re-renderizado na tela)
class ExportacaoScreen extends StatefulWidget {
  const ExportacaoScreen({super.key});

  @override
  State<ExportacaoScreen> createState() => _ExportacaoScreenState();
}

class _ExportacaoScreenState extends State<ExportacaoScreen> {
  String? periodo;
  String? formato;

  final selecionados = <String>{};

  DateTimeRange? customRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exportar Dados:',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),

            _box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecionar período:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  ...[
                    'Última semana',
                    'Último mês',
                    'Últimos 3 meses',
                    'Período personalizado',
                    'Extra',
                  ].map(
                    (e) => RadioListTile(
                      value: e,
                      groupValue: periodo,
                      onChanged: (v) async {
                        periodo = v as String?;
                        if (v == 'Período personalizado') {
                          final now = DateTime.now();
                          customRange = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(now.year - 2),
                            lastDate: DateTime(now.year + 1),
                            initialDateRange: DateTimeRange(
                              start: now.subtract(const Duration(days: 7)),
                              end: now,
                            ),
                          );
                        }
                        setState(() {});
                      },
                      title: Text(e),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            _box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formato:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  RadioListTile(
                    value: 'PDF',
                    groupValue: formato,
                    onChanged: (v) => setState(() => formato = v as String?),
                    title: const Text('PDF (para profissionais)'),
                  ),
                  RadioListTile(
                    value: 'CSV',
                    groupValue: formato,
                    onChanged: (v) => setState(() => formato = v as String?),
                    title: const Text('CSV (planilha)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            _box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conteúdos:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  _check('glicemia', 'Medições de glicemia'),
                  _check('refeicoes', 'Refeições'),
                  _check('medicacoes', 'Medicações'),
                  _check('observacoes', 'Observações'),
                  _check(
                    'graficos',
                    'Gráficos (não implementado neste protótipo)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _bigButton('Gerar arquivo', () async {
              if (formato == null) {
                _msg('Selecione um formato de arquivo.');
                return;
              }

              if (!selecionados.contains('glicemia') &&
                  !selecionados.contains('refeicoes') &&
                  !selecionados.contains('medicacoes') &&
                  !selecionados.contains('observacoes')) {
                _msg('Selecione ao menos um tipo de dado para exportar.');
                return;
              }

              final range = _getSelectedRange();
              final auth = context.read<AuthService>();
              final fs = context.read<FirestoreService>();

              final medicoes = selecionados.contains('glicemia')
                  ? await _getMedicoes(fs, auth.user!.uid, range)
                  : <Map<String, dynamic>>[];

              final refeicoes = selecionados.contains('refeicoes')
                  ? await _getRefeicoes(fs, auth.user!.uid, range)
                  : <Map<String, dynamic>>[];

              final medicacoes = selecionados.contains('medicacoes')
                  ? await _getMedicacoes(fs, auth.user!.uid, range)
                  : <Map<String, dynamic>>[];

              final observacoes = selecionados.contains('observacoes')
                  ? await _getObservacoes(fs, auth.user!.uid, range)
                  : <Map<String, dynamic>>[];

              if (medicoes.isEmpty &&
                  refeicoes.isEmpty &&
                  medicacoes.isEmpty &&
                  observacoes.isEmpty) {
                _msg('Nenhum dado encontrado no período selecionado.');
                return;
              }

              if (formato == 'CSV') {
                final file = await _exportCsv(
                  medicoes: medicoes,
                  refeicoes: refeicoes,
                  medicacoes: medicacoes,
                  observacoes: observacoes,
                  range: range,
                );
                await Share.shareXFiles([
                  XFile(file.path),
                ], text: 'Exportação de dados – Diabetes APP');
              } else {
                final file = await _exportPdf(
                  medicoes: medicoes,
                  refeicoes: refeicoes,
                  medicacoes: medicacoes,
                  observacoes: observacoes,
                  range: range,
                );
                await Share.shareXFiles([
                  XFile(file.path),
                ], text: 'Relatório em PDF – Diabetes APP');
              }
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  DateTimeRange _getSelectedRange() {
    final now = DateTime.now();
    DateTime start = now.subtract(const Duration(days: 7));
    DateTime end = now;

    switch (periodo) {
      case 'Última semana':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'Último mês':
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Últimos 3 meses':
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'Período personalizado':
        if (customRange != null) {
          start = customRange!.start;
          end = customRange!.end;
        }
        break;
    }

    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    return DateTimeRange(start: start, end: endOfDay);
  }

  // Buscas de dados realizadas no banco

  Future<List<Map<String, dynamic>>> _getMedicoes(
    FirestoreService fs,
    String uid,
    DateTimeRange range,
  ) async {
    final snap = await fs
        .medicoes(uid)
        .orderBy('data')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    return snap.docs.map((d) {
      final m = d.data();
      final dt = (m['data'] as Timestamp).toDate();
      return {
        'data': dt,
        'valor': m['valor'],
        'contexto': m['contexto'],
        'contextoOutro': m['contextoOutro'],
        'ultimaRefeicao': (m['ultimaRefeicao'] as Timestamp?)?.toDate(),
        'observacoes': m['observacoes'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getRefeicoes(
    FirestoreService fs,
    String uid,
    DateTimeRange range,
  ) async {
    final snap = await fs
        .refeicoes(uid)
        .orderBy('data')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    return snap.docs.map((d) {
      final m = d.data();
      final dt = (m['data'] as Timestamp).toDate();
      return {
        'data': dt,
        'tipo': m['tipo'],
        'descricao': m['descricao'] ?? '',
        'carboidratos': m['carboidratos'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getMedicacoes(
    FirestoreService fs,
    String uid,
    DateTimeRange range,
  ) async {
    final snap = await fs
        .remedios(uid)
        .orderBy('data')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    return snap.docs.map((d) {
      final m = d.data();
      final dt = (m['data'] as Timestamp).toDate();
      return {
        'data': dt,
        'tipo': m['tipo'] ?? '',
        'nome': m['nome'] ?? '',
        'dosagem': m['dosagem'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getObservacoes(
    FirestoreService fs,
    String uid,
    DateTimeRange range,
  ) async {
    final snap = await fs
        .notas(uid)
        .orderBy('data')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    return snap.docs.map((d) {
      final m = d.data();
      final dt = (m['data'] as Timestamp).toDate();
      return {'data': dt, 'tipo': m['tipo'] ?? '', 'texto': m['texto'] ?? ''};
    }).toList();
  }

  Future<File> _exportCsv({
    required List<Map<String, dynamic>> medicoes,
    required List<Map<String, dynamic>> refeicoes,
    required List<Map<String, dynamic>> medicacoes,
    required List<Map<String, dynamic>> observacoes,
    required DateTimeRange range,
  }) async {
    final auth = context.read<AuthService>();
    final userName = auth.user?.displayName ?? 'Usuário';

    final rows = <List<dynamic>>[];

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    String fmtTime(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    rows.add(['Usuário:', userName]);
    rows.add(['Período:', fmtDate(range.start), 'a', fmtDate(range.end)]);
    rows.add([]);

    if (medicoes.isNotEmpty) {
      rows.add(['=== MEDIÇÕES DE GLICEMIA ===']);
      rows.add([
        'Data',
        'Hora',
        'Glicemia (mg/dL)',
        'Contexto',
        'Última refeição',
        'Observações',
      ]);

      for (final m in medicoes) {
        final dt = m['data'] as DateTime;
        final ultima = m['ultimaRefeicao'] as DateTime?;
        final contexto = _contextoLabel(m['contexto'], m['contextoOutro']);
        rows.add([
          fmtDate(dt),
          fmtTime(dt),
          m['valor'],
          contexto,
          ultima == null ? '' : '${fmtDate(ultima)} ${fmtTime(ultima)}',
          m['observacoes'],
        ]);
      }
      rows.add([]);
    }

    if (refeicoes.isNotEmpty) {
      rows.add(['=== REFEIÇÕES ===']);
      rows.add(['Data', 'Hora', 'Tipo', 'Descrição', 'Carboidratos (g)']);
      for (final r in refeicoes) {
        final dt = r['data'] as DateTime;
        rows.add([
          fmtDate(dt),
          fmtTime(dt),
          r['tipo'] ?? '',
          r['descricao'] ?? '',
          r['carboidratos']?.toString() ?? '',
        ]);
      }
      rows.add([]);
    }

    if (medicacoes.isNotEmpty) {
      rows.add(['=== MEDICAÇÕES ===']);
      rows.add(['Data', 'Hora', 'Tipo', 'Nome', 'Dosagem']);
      for (final med in medicacoes) {
        final dt = med['data'] as DateTime;
        rows.add([
          fmtDate(dt),
          fmtTime(dt),
          med['tipo'],
          med['nome'],
          med['dosagem'],
        ]);
      }
      rows.add([]);
    }

    if (observacoes.isNotEmpty) {
      rows.add(['=== OBSERVAÇÕES ===']);
      rows.add(['Data', 'Hora', 'Tipo', 'Texto']);
      for (final o in observacoes) {
        final dt = o['data'] as DateTime;
        rows.add([fmtDate(dt), fmtTime(dt), o['tipo'], o['texto']]);
      }
      rows.add([]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/exportacao_diabetes.csv');
    await file.writeAsString(csv);
    return file;
  }

  Future<File> _exportPdf({
    required List<Map<String, dynamic>> medicoes,
    required List<Map<String, dynamic>> refeicoes,
    required List<Map<String, dynamic>> medicacoes,
    required List<Map<String, dynamic>> observacoes,
    required DateTimeRange range,
  }) async {
    // Para pegar o nome do usuário, é necessário fazer essa chamada/leitura fora do build do PDF, pq ele não tem acesso ao context do Flutter.
    final auth = context.read<AuthService>();
    final userName = auth.user?.displayName ?? 'Usuário';

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    String fmtTime(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (pw.Context pdfContext) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Relatório de Monitoramento - Diabetes APP',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Período: ${fmtDate(range.start)} a ${fmtDate(range.end)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Usuário: $userName',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),
          );

          pw.Widget sectionTitle(String text) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
            child: pw.Text(
              text,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          );

          if (medicoes.isNotEmpty) {
            widgets.add(sectionTitle('Medições de Glicemia'));
            widgets.add(
              pw.Table.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: [
                  'Data',
                  'Hora',
                  'Valor (mg/dL)',
                  'Contexto',
                  'Última refeição',
                  'Observações',
                ],
                data: medicoes.map((m) {
                  final dt = m['data'] as DateTime;
                  final ultima = m['ultimaRefeicao'] as DateTime?;
                  return [
                    fmtDate(dt),
                    fmtTime(dt),
                    m['valor'].toString(),
                    _contextoLabel(m['contexto'], m['contextoOutro']),
                    ultima == null
                        ? ''
                        : '${fmtDate(ultima)} ${fmtTime(ultima)}',
                    m['observacoes'] ?? '',
                  ];
                }).toList(),
              ),
            );
          }

          if (refeicoes.isNotEmpty) {
            widgets.add(sectionTitle('Refeições'));
            widgets.add(
              pw.Table.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: [
                  'Data',
                  'Hora',
                  'Tipo',
                  'Descrição',
                  'Carboidratos (g)',
                ],
                data: refeicoes.map((r) {
                  final dt = r['data'] as DateTime;
                  return [
                    fmtDate(dt),
                    fmtTime(dt),
                    r['tipo'] ?? '',
                    r['descricao'] ?? '',
                    r['carboidratos']?.toString() ?? '',
                  ];
                }).toList(),
              ),
            );
          }

          if (medicacoes.isNotEmpty) {
            widgets.add(sectionTitle('Medicações'));
            widgets.add(
              pw.Table.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['Data', 'Hora', 'Tipo', 'Nome', 'Dosagem'],
                data: medicacoes.map((med) {
                  final dt = med['data'] as DateTime;
                  return [
                    fmtDate(dt),
                    fmtTime(dt),
                    med['tipo'] ?? '',
                    med['nome'] ?? '',
                    med['dosagem'] ?? '',
                  ];
                }).toList(),
              ),
            );
          }

          if (observacoes.isNotEmpty) {
            widgets.add(sectionTitle('Observações'));
            widgets.add(
              pw.Table.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['Data', 'Hora', 'Tipo', 'Texto'],
                data: observacoes.map((o) {
                  final dt = o['data'] as DateTime;
                  return [
                    fmtDate(dt),
                    fmtTime(dt),
                    o['tipo'] ?? '',
                    o['texto'] ?? '',
                  ];
                }).toList(),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/relatorio_diabetes.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Widget _check(String key, String label) {
    return CheckboxListTile(
      value: selecionados.contains(key),
      onChanged: (v) {
        setState(() {
          if (v == true) {
            selecionados.add(key);
          } else {
            selecionados.remove(key);
          }
        });
      },
      title: Text(label),
    );
  }

  String _contextoLabel(dynamic raw, dynamic outro) {
    final c = (raw ?? '').toString();
    switch (c) {
      case 'Jejum':
        return 'Jejum';
      case '2h pos refeicao':
        return '2h pós refeição';
      case 'Antes de dormir':
        return 'Antes de dormir';
      case 'Outro':
        final extra = (outro ?? '').toString().trim();
        return extra.isEmpty ? 'Outro' : 'Outro: $extra';
      default:
        return c;
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _box(Widget child) => Container(
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
    height: 70,
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
}
