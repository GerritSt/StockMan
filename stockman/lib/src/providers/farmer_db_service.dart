import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/models/farmer_profile.dart';

class FarmerDbService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new farmer to the Farmer collection
  Future<void> addFarmer(Farmer farmer) async {
    await _db.collection('farmers').doc(farmer.id).set({
      'name': farmer.name,
      'email': farmer.email,
      'phone': farmer.phone,
      'location': farmer.location,
    });
  }

  // Fetch a farmer by ID
  Future<Farmer?> getFarmer(String farmerId) async {
    final doc = await _db.collection('farmers').doc(farmerId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    // Fetch farms as well
    final farms = await getFarms(farmerId);
    return Farmer(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'],
      farms: farms,
    );
  }

  // Add a farm to a farmer
  Future<void> addFarm(String farmerId, Farm farm) async {
    // Generate farm ID as farm_XXX
    final farmsSnapshot = await _db.collection('farmers').doc(farmerId).collection('farms').get();
    final farmCount = farmsSnapshot.size + 1;
    final farmId = 'farm_${farmCount.toString().padLeft(3, '0')}';
    await _db.collection('farmers').doc(farmerId).collection('farms').doc(farmId).set({
      'name': farm.name,
      'location': farm.location,
      'type': farm.type,
      'size': farm.size,
    });
  }

  // Fetch all farms for a farmer
  Future<List<Farm>> getFarms(String farmerId) async {
    final snapshot = await _db.collection('farmers').doc(farmerId).collection('farms').get();
    List<Farm> farms = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final camps = await getCamps(farmerId, doc.id);
      farms.add(Farm(
        id: doc.id,
        name: data['name'] ?? '',
        location: data['location'],
        type: data['type'] ?? '',
        size: data['size'] ?? 0,
        camps: camps,
        cattle: [], // Cattle handled separately
      ));
    }
    return farms;
  }

  // Add a camp to a farm
  Future<void> addCamp(String farmerId, String farmId, Camp camp) async {
    // Generate camp ID as camp_FFFFCCC (FFF=farm number, CCC=camp number)
    final farmNum = int.tryParse(farmId.split('_').last) ?? 1;
    final campsSnapshot = await _db.collection('farmers').doc(farmerId).collection('farms').doc(farmId).collection('camps').get();
    final campCount = campsSnapshot.size + 1;
    final campId = 'camp_${farmNum.toString().padLeft(3, '0')}${campCount.toString().padLeft(3, '0')}';
    await _db.collection('farmers').doc(farmerId).collection('farms').doc(farmId).collection('camps').doc(campId).set({
      'name': camp.name,
      'location': camp.location,
      'size': camp.size,
    });
  }

  // Fetch all camps for a farm
  Future<List<Camp>> getCamps(String farmerId, String farmId) async {
    final snapshot = await _db.collection('farmers').doc(farmerId).collection('farms').doc(farmId).collection('camps').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Camp(
        id: doc.id,
        name: data['name'] ?? '',
        location: data['location'],
        size: data['size'] ?? 0,
      );
    }).toList();
  }
} 