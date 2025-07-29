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
  Future<void> addCattle(
      {required String farmerId,
      required String farmId,
      required String campId,
      required Cattle cattle,
      required String cattleId}) async {
    // Add the new cattle to firebase
    await _db
        .collection('farmers')
        .doc(farmerId)
        .collection('farms')
        .doc(farmId)
        .collection('camps')
        .doc(campId)
        .collection('cattle')
        .doc(cattleId)
        .set(cattle.toMap());
  }

  // Delete a cattle
  Future<void> deleteCattle({
    required String farmerId,
    required String farmId,
    required String campId,
    required String cattleId,
  }) async {
    await _db
        .collection('farmers')
        .doc(farmerId)
        .collection('farms')
        .doc(farmId)
        .collection('camps')
        .doc(campId)
        .collection('cattle')
        .doc(cattleId)
        .delete();
  }
}
