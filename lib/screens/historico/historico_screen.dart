import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  String filtro = "medicoes";

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final df = DateFormat('dd/MM/yyyy – HH:mm');

    // Seleciona a coleção a ser filtrada
    Stream<QuerySnapshot> streamSelecionado() {
      switch (filtro) {
        case "refeicoes":
          return fs
              .refeicoes(auth.user!.uid)
              .orderBy("data", descending: true)
              .snapshots();

        case "remedios":
          return fs
              .remedios(auth.user!.uid)
              .orderBy("data", descending: true)
              .snapshots();

        case "notas":
          return fs
              .notas(auth.user!.uid)
              .orderBy("data", descending: true)
              .snapshots();

        default:
          return fs
              .medicoes(auth.user!.uid)
              .orderBy("data", descending: true)
              .snapshots();
      }
    }

    return Scaffold(
      body: Column(
        children: [
          // aqui ficam os botões do filtro
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _btnFiltro("Medições", "medicoes"),
              _btnFiltro("Refeições", "refeicoes"),
              _btnFiltro("Remédios", "remedios"),
              _btnFiltro("Notas", "notas"),
            ],
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: streamSelecionado(),
              builder: (c, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum registro encontrado.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final d = docs[i].data()! as Map<String, dynamic>;
                    final dt = (d["data"] as Timestamp).toDate();

                    switch (filtro) {
                      case "refeicoes":
                        return _itemRefeicao(
                          context,
                          docs[i].reference,
                          d,
                          dt,
                          df,
                        );

                      case "remedios":
                        return _itemRemedio(
                          context,
                          docs[i].reference,
                          d,
                          dt,
                          df,
                        );

                      case "notas":
                        return _itemNota(context, docs[i].reference, d, dt, df);

                      default:
                        return _itemMedicao(
                          context,
                          docs[i].reference,
                          d,
                          dt,
                          df,
                        );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _btnFiltro(String label, String valor) {
    final selecionado = filtro == valor;

    return GestureDetector(
      onTap: () => setState(() => filtro = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _itemMedicao(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> d,
    DateTime dt,
    DateFormat df,
  ) {
    return _cardBase(
      df.format(dt),
      "${d['valor']} mg/dL",
      [
        if ((d['contexto'] ?? '').isNotEmpty) "Contexto: ${d['contexto']}",
        if ((d['observacoes'] ?? '').isNotEmpty) "Obs: ${d['observacoes']}",
      ].join("\n"),
      () => _editarMedicao(context, ref, d),
      () => ref.delete(),
    );
  }

  Widget _itemRefeicao(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> d,
    DateTime dt,
    DateFormat df,
  ) {
    final tipo = d["tipo"] ?? "Refeição";
    final descricao = d["descricao"] ?? "";
    final carbs = d["carboidratos"];

    final detalhes = [
      if (carbs != null) "Carboidratos: ${carbs} g",
      if (descricao.isNotEmpty) descricao,
    ].join("\n");

    return _cardBase(
      df.format(dt),
      tipo,
      detalhes,
      () => _editarRefeicao(context, ref, d),
      () => ref.delete(),
    );
  }

  Widget _itemRemedio(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> d,
    DateTime dt,
    DateFormat df,
  ) {
    return _cardBase(
      df.format(dt),
      "${d['nome']} (${d['dosagem']})",
      "Tipo: ${d['tipo']}",
      () => _editarRemedio(context, ref, d),
      () => ref.delete(),
    );
  }

  Widget _itemNota(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> d,
    DateTime dt,
    DateFormat df,
  ) {
    return _cardBase(
      df.format(dt),
      "Nota — ${d['tipo'] ?? 'Sem tipo'}",
      d["texto"] ?? "",
      () => _editarNota(context, ref, d),
      () => ref.delete(),
    );
  }

  Widget _cardBase(
    String titulo,
    String subtitulo,
    String detalhes,
    VoidCallback editar,
    VoidCallback excluir,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          "$titulo — $subtitulo",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(detalhes),
        leading: IconButton(
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: editar,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: excluir,
        ),
      ),
    );
  }

  void _editarMedicao(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> dados,
  ) {
    final valorCtrl = TextEditingController(
      text: dados['valor']?.toString() ?? '',
    );
    final obsCtrl = TextEditingController(text: dados['observacoes'] ?? '');
    String? contexto = dados['contexto'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Medição'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: valorCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Valor (mg/dL)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Contexto:'),
              RadioListTile(
                value: 'Jejum',
                groupValue: contexto,
                title: const Text('Jejum'),
                onChanged: (v) => setState(() => contexto = v),
              ),
              RadioListTile(
                value: '2h pos refeicao',
                groupValue: contexto,
                title: const Text('2h após refeição'),
                onChanged: (v) => setState(() => contexto = v),
              ),
              RadioListTile(
                value: 'Antes de dormir',
                groupValue: contexto,
                title: const Text('Antes de dormir'),
                onChanged: (v) => setState(() => contexto = v),
              ),
              RadioListTile(
                value: 'Outro',
                groupValue: contexto,
                title: const Text('Outro'),
                onChanged: (v) => setState(() => contexto = v),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: obsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Observações",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.update({
                'valor': int.tryParse(valorCtrl.text.trim()) ?? 0,
                'contexto': contexto,
                'observacoes': obsCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _editarRefeicao(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> d,
  ) {
    String? tipo = d['tipo'];
    final descCtrl = TextEditingController(text: d['descricao'] ?? '');
    final carbsCtrl = TextEditingController(
      text: d['carboidratos'] != null ? d['carboidratos'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => AlertDialog(
          title: const Text("Editar Refeição"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Tipo de refeição:"),
                ...['Café da manhã', 'Almoço', 'Lanche', 'Jantar', 'Extra'].map(
                  (e) => RadioListTile(
                    value: e,
                    groupValue: tipo,
                    title: Text(e),
                    onChanged: (v) => setStateSB(() => tipo = v),
                  ),
                ),

                const SizedBox(height: 12),

                const Text("Descrição:"),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                const Text("Carboidratos (opcional):"),
                TextField(
                  controller: carbsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.update({
                  'tipo': tipo,
                  'descricao': descCtrl.text.trim(),
                  'carboidratos': double.tryParse(carbsCtrl.text.trim()),
                });

                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  void _editarRemedio(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> d,
  ) {
    final nomeCtrl = TextEditingController(text: d['nome'] ?? '');
    final doseCtrl = TextEditingController(text: d['dosagem'] ?? '');

    String? tipo = d['tipo'] ?? "Medicação oral";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Remédio"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                  labelText: "Nome do medicamento",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: doseCtrl,
                decoration: const InputDecoration(
                  labelText: "Dosagem",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                "Tipo de medicação:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile(
                value: "Insulina",
                groupValue: tipo,
                title: const Text("Insulina"),
                onChanged: (v) => setState(() => tipo = v.toString()),
              ),
              RadioListTile(
                value: "Medicação oral",
                groupValue: tipo,
                title: const Text("Medicação oral"),
                onChanged: (v) => setState(() => tipo = v.toString()),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            child: const Text("Salvar"),
            onPressed: () async {
              await ref.update({
                'nome': nomeCtrl.text.trim(),
                'dosagem': doseCtrl.text.trim(),
                'tipo': tipo,
              });

              if (context.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _editarNota(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> d,
  ) {
    final textoCtrl = TextEditingController(text: d["texto"] ?? "");
    String? tipo = d["tipo"];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Nota"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tipo de observação:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile(
                value: "Exercício físico",
                groupValue: tipo,
                title: const Text("Exercício físico"),
                onChanged: (v) => setState(() => tipo = v.toString()),
              ),
              RadioListTile(
                value: "Ficou doente",
                groupValue: tipo,
                title: const Text("Ficou doente"),
                onChanged: (v) => setState(() => tipo = v.toString()),
              ),
              RadioListTile(
                value: "Estresse/ansiedade",
                groupValue: tipo,
                title: const Text("Estresse/ansiedade"),
                onChanged: (v) => setState(() => tipo = v.toString()),
              ),
              RadioListTile(
                value: "Outro",
                groupValue: tipo,
                title: const Text("Outro"),
                onChanged: (v) => setState(() => tipo = v.toString()),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: textoCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Observações",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.update({'tipo': tipo, 'texto': textoCtrl.text.trim()});

              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }
}
