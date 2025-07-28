import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/config/constants.dart';
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
  Future<Farmer> getFarmer(String farmerUID) async {
    // Do a firebase fetch
    final docu = await _db.collection('farmers').doc(farmerUID).get();
    // Fetch farms as well
    final farms = await getFarms(farmerUID);
    // Return a Farmer object created using the factory constructor in farmer_profile
    return Farmer.fromSnapshot(
      doc: docu,
      farms: farms,
    );
  }

  // Add a farm to a farmer
  Future<void> addFarm(String farmerUID, Farm farm) async {
    // Generate farm ID as farm_XXX
    final farmsSnapshot = await _db
        .collection('farmers')
        .doc(farmerUID)
        .collection('farms')
        .get();
    final farmCount = farmsSnapshot.size + 1;
    final farmID = 'farm_${farmCount.toString().padLeft(3, '0')}';
    await _db
        .collection('farmers')
        .doc(farmerUID)
        .collection('farms')
        .doc(farmID)
        .set({
      'name': farm.name,
      'location': farm.location,
      'type': farm.type,
      'size': farm.size,
    });
  }

  // Fetch all farms for a farmer
  Future<List<Farm>> getFarms(String farmerUID) async {
    final snapshot = await _db
        .collection('farmers')
        .doc(farmerUID)
        .collection('farms')
        .get();
    List<Farm> farms = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final camps = await getCamps(farmerUID, doc.id);
      farms.add(Farm(
        id: doc.id,
        name: data['name'] ?? '',
        location: data['location'] ?? NOWHERE,
        type: data['type'] ?? '',
        size: data['size'] ?? 0,
        camps: camps,
        cattle: [], // Cattle handled separately
      ));
    }
    return farms;
  }

  // Add a camp to a farm
  Future<void> addCamp(String farmerUID, String farmID, Camp camp) async {
    // Generate camp ID as camp_FFFFCCC (FFF=farm number, CCC=camp number)
    final farmNum = int.tryParse(farmID.split('_').last) ?? 1;
    final campsSnapshot = await _db
        .collection('farmers')
        .doc(farmerUID)
        .collection('farms')
        .doc(farmID)
        .collection('camps')
        .get();
    final campCount = campsSnapshot.size + 1;
    final campId =
        'camp_${farmNum.toString().padLeft(3, '0')}${campCount.toString().padLeft(3, '0')}';
    await _db
        .collection('farmers')
        .doc(farmerUID)
        .collection('farms')
        .doc(farmID)
        .collection('camps')
        .doc(campId)
        .set({
      'name': camp.name,
      'location': camp.location,
      'size': camp.size,
    });
  }

  // Fetch all camps for a farm
  Future<List<Camp>> getCamps(String farmerUID, String farmID) async {
    dlog("Fetch camps for UID: $farmerUID, farmID: $farmID");

    final snapshot = await _db
        .collection('farmers')
        .doc(farmerUID)
        .collection('farms')
        .doc(farmID)
        .collection('camps')
        .get();

    dlog("Snapshot.docs: ${snapshot.docs}");

    for (var doc in snapshot.docs) {
      dlog("Camp doc: ${doc.id}, data: ${doc.data()}");
    }
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
