import 'package:cloud_firestore/cloud_firestore.dart';

class CattleDbService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // fetch all the catlle from the "cattle" collection
  Future<List<Map<String, dynamic>>> getCattle() async {
    QuerySnapshot snapshot = await _db.collection('cattle').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Add entry to cattle collection
  Future<void> addCattle(Map<String, dynamic> cattleData) async {
    await _db.collection('cattle').add(cattleData);
  }
}