import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class GraficoScreen extends StatelessWidget {
  const GraficoScreen({super.key});

  Future<String> _nomeUsuario(BuildContext context) async {
    final auth = context.read<AuthService>();
    final u = auth.user!;
    if (u.displayName != null && u.displayName!.trim().isNotEmpty) {
      return u.displayName!;
    }
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(u.uid)
        .collection('perfil')
        .doc('principal')
        .get();
    return (snap.data()?['nomeCompleto'] as String?) ?? 'usuário';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.medicoes(auth.user!.uid).orderBy('data').snapshots(),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = s.data!.docs;
          final spots = <FlSpot>[];
          for (int i = 0; i < docs.length; i++) {
            final m = docs[i].data()! as Map<String, dynamic>;
            final v = (m['valor'] as num).toDouble();
            spots.add(FlSpot(i.toDouble(), v));
          }

          final hasData = spots.isNotEmpty;
          final lastY = hasData ? spots.last.y : 0.0;
          final lastX = hasData ? spots.last.x : 0.0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder<String>(
                  future: _nomeUsuario(context),
                  builder: (_, snap) => Text(
                    'Olá, ${snap.data ?? 'usuário'}!',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                ),
                const SizedBox(height: 8),
                if (!hasData)
                  const Expanded(
                      child: Center(child: Text('Sem dados ainda.')))
                else
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        backgroundColor: const Color(0xFFF2EEEE),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (v) =>
                              FlLine(color: Colors.black12, strokeWidth: 1),
                          getDrawingVerticalLine: (v) => FlLine(
                              color: Colors.black12,
                              strokeWidth: 1,
                              dashArray: [6, 6]),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            left: BorderSide(color: Colors.black, width: 2),
                            bottom: BorderSide(color: Colors.black, width: 2),
                            right: BorderSide(color: Colors.transparent),
                            top: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) =>
                                  Padding(padding: const EdgeInsets.only(top: 6), child: Text('${value.toInt()}')),
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: false,
                            barWidth: 3,
                            color: Colors.black,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                                show: true, color: Colors.black12),
                          ),
                        ],
                        extraLinesData: ExtraLinesData(verticalLines: [
                          VerticalLine(
                              x: lastX,
                              strokeWidth: 2,
                              color: Colors.black,
                              dashArray: [6, 6]),
                        ]),
                        lineTouchData: LineTouchData(enabled: true),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (hasData)
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                            color: Colors.limeAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('$lastY mg/dL',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
