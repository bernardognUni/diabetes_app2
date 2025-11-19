import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> usuarios() =>
      _db.collection('usuarios');

  // Subcoleções do usuário
  CollectionReference<Map<String, dynamic>> medicoes(String uid) =>
      usuarios().doc(uid).collection('medicoes');

  CollectionReference<Map<String, dynamic>> refeicoes(String uid) =>
      usuarios().doc(uid).collection('refeicoes');

  CollectionReference<Map<String, dynamic>> remedios(String uid) =>
      usuarios().doc(uid).collection('remedios');

  CollectionReference<Map<String, dynamic>> notas(String uid) =>
      usuarios().doc(uid).collection('notas');

  CollectionReference<Map<String, dynamic>> alertas(String uid) =>
      usuarios().doc(uid).collection('alertas');

  DocumentReference<Map<String, dynamic>> perfil(String uid) =>
      usuarios().doc(uid).collection('perfil').doc('principal');

  // Catálogo global (somente leitura no app)
  CollectionReference<Map<String, dynamic>> catalogoMedicamentos() =>
      _db.collection('catalogo_medicamentos');
}
