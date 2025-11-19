// lib/screens/alerts/alerts_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AlertsListScreen extends StatelessWidget {
  const AlertsListScreen({super.key});

  Future<void> _seedExemplos(FirestoreService fs, String uid) async {
    final col = fs.alertas(uid);
    await col.add({
      'titulo': '⚠️ CRÍTICO',
      'descricao': 'Glicemia abaixo de 70 mg/dL',
      'tipo': 'critico',
      'data': Timestamp.now(),
      'ativo': true,
    });
    await col.add({
      'titulo': '⚡ ATENÇÃO',
      'descricao': 'Jejum há 3 horas',
      'tipo': 'atencao',
      'data': Timestamp.now(),
      'ativo': true,
    });
    await col.add({
      'titulo': '💡 LEMBRETE',
      'descricao': 'Hora da medicação',
      'tipo': 'lembrete',
      'data': Timestamp.now(),
      'ativo': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas e Lembretes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.alertas(auth.user!.uid).orderBy('data', descending: false).snapshots(),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            // Popula exemplos na primeira abertura
            _seedExemplos(fs, auth.user!.uid);
            return const Center(child: Text('Carregando exemplos...'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Alertas Ativos:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...docs.map((d) {
                final m = d.data()! as Map<String, dynamic>;
                final type = (m['tipo'] as String?) ?? 'lembrete';
                Color bg = const Color(0xFF4DA3FF);
                if (type == 'critico') bg = const Color(0xFFFF5555);
                else if (type == 'atencao') bg = const Color(0xFFFFFF55);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text("${m['titulo']}\n${m['descricao'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
                      InkWell(onTap: ()=> d.reference.delete(), child: const Icon(Icons.close)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: ()=> Navigator.pushNamed(context, '/alertas/novo'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D43FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Adicionar Lembrete', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              ),
            ],
          );
        },
      ),
    );
  }
}
