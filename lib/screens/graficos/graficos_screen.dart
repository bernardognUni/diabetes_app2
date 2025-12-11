import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class GraficosScreen extends StatefulWidget {
  const GraficosScreen({super.key});

  @override
  State<GraficosScreen> createState() => _GraficosScreenState();
}

class _GraficosScreenState extends State<GraficosScreen> {
  String periodoSelecionado = 'Mensal';
  DateTimeRange? customRange;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gráficos')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFiltros(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fs.medicoes(auth.user!.uid).orderBy('data').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Sem dados ainda.'));
                }

                final filtrados = _filtrarMedicoes(docs);
                if (filtrados.isEmpty) {
                  return const Center(
                    child: Text("Sem dados no período selecionado."),
                  );
                }

                final spots = <FlSpot>[];
                final labels = <double, String>{};
                final dfDia = DateFormat('dd/MM HH:mm');
                final dfSemana = DateFormat('dd/MM');
                final dfMes = DateFormat('dd/MM');

                final intervalo = periodoSelecionado;

                for (int i = 0; i < filtrados.length; i++) {
                  final m = filtrados[i].data()! as Map<String, dynamic>;
                  final dt = (m['data'] as Timestamp).toDate();
                  final valor = (m['valor'] as num).toDouble();

                  spots.add(FlSpot(i.toDouble(), valor));

                  if (intervalo == 'Diário') {
                    labels[i.toDouble()] = DateFormat('HH:mm').format(dt);
                  } else if (intervalo == 'Semanal') {
                    labels[i.toDouble()] = dfSemana.format(dt);
                  } else if (intervalo == 'Mensal') {
                    if (i % 3 == 0) {
                      // reduz a poluição visual
                      labels[i.toDouble()] = dfMes.format(dt);
                    }
                  } else {
                    labels[i.toDouble()] = dfDia.format(dt);
                  }
                }

                final lastSpot = spots.last;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEDED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: LineChart(
                            LineChartData(
                              backgroundColor: const Color(0xFFEDEDED),
                              minY: 0,
                              borderData: FlBorderData(show: true),
                              gridData: FlGridData(show: true),
                              lineTouchData: LineTouchData(enabled: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: false,
                                  barWidth: 2,
                                  color: Colors.black,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.black12,
                                  ),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    reservedSize: 34,
                                    getTitlesWidget: (value, meta) {
                                      return Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          labels[value] ?? '',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 50,
                                    getTitlesWidget: (value, _) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              extraLinesData: ExtraLinesData(
                                verticalLines: [
                                  VerticalLine(
                                    x: lastSpot.x,
                                    strokeWidth: 2,
                                    color: Colors.black,
                                    dashArray: [6, 6],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.limeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${lastSpot.y.toStringAsFixed(1)} mg/dL',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Filtro por período
  List<DocumentSnapshot> _filtrarMedicoes(List<DocumentSnapshot> docs) {
    final agora = DateTime.now();
    DateTime inicio;

    switch (periodoSelecionado) {
      case 'Diário':
        inicio = agora.subtract(const Duration(hours: 24));
        break;
      case 'Semanal':
        inicio = agora.subtract(const Duration(days: 7));
        break;
      case 'Mensal':
        inicio = agora.subtract(const Duration(days: 30));
        break;
      case 'Personalizado':
        if (customRange != null) {
          inicio = customRange!.start;
          return docs.where((d) {
            final dt = (d['data'] as Timestamp).toDate();
            return dt.isAfter(customRange!.start) &&
                dt.isBefore(customRange!.end);
          }).toList();
        }
        inicio = agora.subtract(const Duration(days: 30));
        break;
      default:
        inicio = agora.subtract(const Duration(days: 30));
    }

    return docs.where((d) {
      final dt = (d['data'] as Timestamp).toDate();
      return dt.isAfter(inicio);
    }).toList();
  }

  // Widgets de seleção de filtro
  Widget _buildFiltros(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton<String>(
          value: periodoSelecionado,
          items: const [
            DropdownMenuItem(value: 'Diário', child: Text('Diário')),
            DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
            DropdownMenuItem(value: 'Mensal', child: Text('Mensal')),
            DropdownMenuItem(
              value: 'Personalizado',
              child: Text('Personalizado'),
            ),
          ],
          onChanged: (v) async {
            if (v == 'Personalizado') {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (range != null) {
                customRange = range;
              }
            }
            setState(() => periodoSelecionado = v!);
          },
        ),
      ],
    );
  }
}
