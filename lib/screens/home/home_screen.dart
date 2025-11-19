import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
//import '../graficos/grafico_screen.dart';
import '../refeicao/refeicao_screen.dart';
import '../remedio/remedio_screen.dart';
import '../medir/medir_screen.dart';
import '../notas/notas_screen.dart';
import '../historico/historico_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _InicioScreen(),
      const RefeicaoScreen(),
      const RemedioScreen(),
      const MedirScreen(),
      const NotasScreen(),
      const HistoricoScreen(),
    ];

    final titles = [
      'Tela Inicial',
      'Refeição',
      'Remédio',
      'Medir',
      'Notas',
      'Histórico',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final auth = context.read<AuthService>();
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Refeição',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Remédio',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.autorenew), label: 'Medir'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Notas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
        onTap: (i) => setState(() => index = i),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF7EC3FF)),
              child: Center(
                child: Text(
                  'Diabetes APP',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () => Navigator.pushNamed(context, '/perfil'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Alertas e Lembretes'),
              onTap: () => Navigator.pushNamed(context, '/alertas'),
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Gráficos'),
              onTap: () => Navigator.pushNamed(context, '/graficos'),
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Exportação'),
              onTap: () => Navigator.pushNamed(context, '/exportacao'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InicioScreen extends StatelessWidget {
  const _InicioScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final uid = auth.user!.uid;

    final medicoesStream = fs
        .medicoes(uid)
        .orderBy('data', descending: false)
        .snapshots();

    final refeicoesStream = fs.refeicoes(uid).snapshots();
    final remediosStream = fs.remedios(uid).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: medicoesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(
            child: Text(
              'Nenhuma medição encontrada.',
              style: TextStyle(fontSize: 20),
            ),
          );

        final dados = docs.map((d) {
          final m = d.data() as Map<String, dynamic>;
          final data = (m['data'] as Timestamp).toDate();
          final valor = (m['valor'] ?? 0).toDouble();
          return FlSpot(data.hour + (data.minute / 60), valor);
        }).toList();

        final ultima = docs.last.data() as Map<String, dynamic>;
        final ultimaValor = ultima['valor'] ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: refeicoesStream,
          builder: (context, refeicaoSnap) {
            final refeicoes = refeicaoSnap.data?.docs ?? [];

            return StreamBuilder<QuerySnapshot>(
              stream: remediosStream,
              builder: (context, remedioSnap) {
                final remedios = remedioSnap.data?.docs ?? [];

                const metaMin = 90.0;
                const metaMax = 180.0;

                final refeicaoPoints = refeicoes.map((r) {
                  final data = (r['data'] as Timestamp).toDate();
                  return FlSpot(data.hour + (data.minute / 60), metaMin - 5);
                }).toList();

                final remedioPoints = remedios.map((r) {
                  final data = (r['data'] as Timestamp).toDate();
                  return FlSpot(data.hour + (data.minute / 60), metaMax + 5);
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${auth.user?.displayName ?? 'usuário(a)'}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Text(
                          'Última medição: ${ultimaValor.toStringAsFixed(0)} mg/dL',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Glicemia ao longo do dia',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            backgroundColor: const Color(0xFFF5F9FF),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 30,
                            ),
                            borderData: FlBorderData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (v, meta) {
                                    final hora = v.floor();
                                    return Text(
                                      '$hora h',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: dados,
                                isCurved: false,
                                color: Colors.black,
                                barWidth: 2,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.blue.withOpacity(0.1),
                                ),
                              ),
                            ],
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: metaMin,
                                  color: Colors.green,
                                  strokeWidth: 2,
                                  dashArray: [6, 3],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.bottomLeft,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    labelResolver: (_) => 'Meta mínima (90)',
                                  ),
                                ),
                                HorizontalLine(
                                  y: metaMax,
                                  color: Colors.green,
                                  strokeWidth: 2,
                                  dashArray: [6, 3],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topLeft,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    labelResolver: (_) => 'Meta máxima (180)',
                                  ),
                                ),
                              ],
                            ),
                            lineTouchData: LineTouchData(enabled: true),
                          ),
                          //swapAnimationDuration: const Duration(milliseconds: 500),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.restaurant, color: Colors.orange),
                          SizedBox(width: 6),
                          Text('Refeição'),
                          SizedBox(width: 20),
                          Icon(Icons.medication, color: Colors.purple),
                          SizedBox(width: 6),
                          Text('Medicação'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
