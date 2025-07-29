import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/models/cattle_profile.dart';

class CattleDbService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all cattle for a specific camp
  Future<List<Cattle>> getCattle({
    required String farmerId,
    required String farmId,
    required String campId,
  }) async {
    QuerySnapshot snapshot = await _db
        .collection('farmers')
        .doc(farmerId)
        .collection('farms')
        .doc(farmId)
        .collection('camps')
        .doc(campId)
        .collection('cattle')
        .get();
    return snapshot.docs.map((doc) => Cattle.fromSnapshot(doc)).toList();
  }

  // Add a cattle entry to a specific camp
  Future<void> addCattle({
    required String farmerId,
    required String farmId,
    required String campId,
    required Cattle cattle,
  }) async {
    // Generate deterministic cattle ID
    final dateOfBirth = cattle.dateOfBirth;
    final sex = cattle.sex;
    final rand =
        (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    final dateStr =
        " ${dateOfBirth.year.toString().padLeft(4, '0')}${dateOfBirth.month.toString().padLeft(2, '0')}${dateOfBirth.day.toString().padLeft(2, '0')}";
    final newcattleId = "${dateStr}_${sex}_$rand";

    // Add the new cattle to firebase
    await _db
        .collection('farmers')
        .doc(farmerId)
        .collection('farms')
        .doc(farmId)
        .collection('camps')
        .doc(campId)
        .collection('cattle')
        .doc(newcattleId)
        .set(cattle.toMap());
  }
}
