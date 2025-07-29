import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/providers/farmer_db_service.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';

/// This is the FullFarmerModel.
/// It consists of 5 attributes
///   1. UID - the UID of the farmer
///   2. farmer - Farmer object
///   3. farms - map of all the Farm objects
///   4. camps - map of all the Camp objects
///   5. cattleFuture - Future Map of all the cattle objects
///
/// Initialization of the class:
///  - Constructed using the UID of the farmer
///  - Populate the farmer object through the firebase FarmerDbService
///  - Populate the farms map through the list of farms from farmer object
///  - Populate the camps map from the farms map
///  - Populate the cattleFuture through the firebase CattleDbService
///
/// //
class FullFarmerModel {
  final String uid;
  Farmer farmer = Farmer(
    id: '',
    name: 'John',
    surname: 'Doe',
    email: 'john@doe.com',
    phone: '',
    location: NOWHERE,
    farms: [],
  );

  // Maps for farms, camps, and cattle
  Map<String, Farm> farms = {};
  Map<String, Camp> camps = {};
  // Change cattle to a Future
  Future<Map<String, Cattle>> cattleFuture = Future.value({});

  // Database services
  final FarmerDbService _farmerDbService = FarmerDbService();
  final CattleDbService _cattleDbService = CattleDbService();

  FullFarmerModel({required this.uid});

  // Initialization function
  Future<void> initialize() async {
    farmer = await _farmerDbService.getFarmer(uid);

    await _getFarms();
    await _getCamps();
    // Assign cattleFuture for lazy loading
    cattleFuture = _getCattle();
  }

  // Get farms
  Future<void> _getFarms() async {
    dlog('Get farms');
    List<Farm> farmList = farmer.farms;
    farms = {for (var farm in farmList) farm.id: farm};
    dlog("farms = $farms");
  }

  // Get camps
  Future<void> _getCamps() async {
    dlog("Get camps");
    Map<String, Camp> campMap = {};
    for (var farm in farms.values) {
      List<Camp> campList = farm.camps;
      for (var camp in campList) {
        campMap[camp.id] = camp;
      }
    }
    camps = campMap;
    dlog("camps = $camps");
  }

  // Get cattle now returns a Future<Map<String, Cattle>>
  Future<Map<String, Cattle>> _getCattle() async {
    Map<String, Cattle> cattleMap = {};
    // dlog('Now gettting the cattle from the full farmer model');
    // dlog(farms.toString());
    for (var farm in farms.values) {
      // dlog("Farm: ${farm.id}");
      for (var camp in camps.values) {
        // dlog('Camp: ${camp.id}');
        List<Cattle> cattleList = await _cattleDbService.getCattle(
          farmerId: uid,
          farmId: farm.id,
          campId: camp.id,
        );
        for (var cow in cattleList) {
          cattleMap[cow.id] = cow;
        }
      }
    }
    // dlog('Returning cattleMap: ' + cattleMap.toString());
    return cattleMap;
  }

  // Public refresh functions
  Future<void> refreshFarms() async => await _getFarms();
  Future<void> refreshCamps() async => await _getCamps();
  // Public refresh function for cattle
  void refreshCattle() {
    cattleFuture = _getCattle();
  }

  // Public getters for maps
  Map<String, Farm> getFarms() => farms;
  Map<String, Camp> getCamps() => camps;
  // Getter for cattle future
  Future<Map<String, Cattle>> getCattle() => cattleFuture;
}
