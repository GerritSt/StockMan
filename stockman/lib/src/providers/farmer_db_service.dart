// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  FarmerDbService() {
    dlog('FarmerDbService initialized with Supabase');
  }

  // Add a new farmer to the Farmer collection
  Future<void> addFarmer(Farmer farmer) async {
    try {
      // Check if farmer already exists
      final existing = await _supabase
          .from('farmers')
          .select('id')
          .eq('id', farmer.id)
          .maybeSingle();

      if (existing != null) {
        // Update existing farmer
        await _supabase.from('farmers').update({
          'name': farmer.name,
          'surname': farmer.surname,
          'email': farmer.email,
          'phone': farmer.phone,
        }).eq('id', farmer.id);
        dlog('Farmer updated successfully');
      } else {
        // Insert new farmer (use auth user id as the primary key)
        await _supabase.from('farmers').insert({
          'id': farmer.id, // Use auth user ID as primary key
          'name': farmer.name,
          'surname': farmer.surname,
          'email': farmer.email,
          'phone': farmer.phone,
        });
        dlog('Farmer added successfully');
      }
    } catch (e) {
      dlog('Error adding farmer: $e');
      rethrow;
    }
  }

  // Fetch a farmer by auth ID (from Supabase auth)
  Future<Farmer> getFarmer(String authUID) async {
    try {
      dlog('Fetching farmer for id: $authUID');

      // Fetch farmer data (id is the auth user id)
      final farmerResponse = await _supabase
          .from('farmers')
          .select()
          .eq('id', authUID)
          .maybeSingle();

      if (farmerResponse == null) {
        dlog('No farmer found, returning dummy farmer');
        return Farmer(
          id: '',
          name: 'New',
          surname: 'User',
          email: _supabase.auth.currentUser?.email ?? 'unknown@email.com',
          phone: '',
          location: NOWHERE,
          farms: [],
        );
      }

      // Fetch farms for this farmer
      final farms = await getFarms(farmerResponse['id']);

      return Farmer.fromJson(farmerResponse, farms: farms);
    } catch (e) {
      dlog('Error fetching farmer: $e');
      rethrow;
    }
  }

  // Add a farm to a farmer
  Future<void> addFarm(String farmerUID, Farm farm) async {
    try {
      // farmerUID is the auth user id (same as farmers.id)
      await _supabase.from('farms').insert({
        'farmer_id': farmerUID,
        'name': farm.name,
        'location': '${farm.location.latitude},${farm.location.longitude}',
      });
      dlog('Farm added successfully');
    } catch (e) {
      dlog('Error adding farm: $e');
      rethrow;
    }
  }

  // Fetch all farms for a farmer
  Future<List<Farm>> getFarms(String farmerId) async {
    try {
      dlog('Fetching farms for farmer_id: $farmerId');

      final farmsResponse =
          await _supabase.from('farms').select().eq('farmer_id', farmerId);

      List<Farm> farms = [];
      for (var farmData in farmsResponse) {
        final camps = await getCamps(farmData['id']);
        farms.add(Farm(
          id: farmData['id'],
          name: farmData['name'] ?? '',
          location: _parseGeoPoint(farmData['location']),
          type: farmData['type'] ?? 'Cattle',
          size: farmData['size'] ?? 0,
          camps: camps,
          cattle: [], // Cattle handled separately
        ));
      }

      dlog('Fetched ${farms.length} farms');
      return farms;
    } catch (e) {
      dlog('Error fetching farms: $e');
      return [];
    }
  }

  // Add a camp to a farm
  Future<void> addCamp(String farmerUID, String farmID, Camp camp) async {
    try {
      await _supabase.from('camps').insert({
        'farm_id': farmID,
        'name': camp.name,
        'location': '${camp.location.latitude},${camp.location.longitude}',
        'size': camp.size,
      });
      dlog('Camp added successfully');
    } catch (e) {
      dlog('Error adding camp: $e');
      rethrow;
    }
  }

  // Fetch all camps for a farm
  Future<List<Camp>> getCamps(String farmID) async {
    try {
      dlog("Fetching camps for farmID: $farmID");

      final campsResponse =
          await _supabase.from('camps').select().eq('farm_id', farmID);

      dlog("Fetched ${campsResponse.length} camps");

      return campsResponse.map<Camp>((campData) {
        return Camp(
          id: campData['id'],
          name: campData['name'] ?? '',
          location: _parseGeoPoint(campData['location']),
          size: campData['size'] ?? 0,
        );
      }).toList();
    } catch (e) {
      dlog('Error fetching camps: $e');
      return [];
    }
  }

  // Update last sign-in timestamp for a farmer
  Future<void> updateLastSignin(String farmerId) async {
    try {
      await _supabase.from('farmers').update({
        'last_signin': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', farmerId);
      dlog('Last sign-in updated for farmer: $farmerId');
    } catch (e) {
      dlog('Error updating last sign-in: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  // Helper method to parse GeoPoint from string
  GeoPoint _parseGeoPoint(dynamic locationData) {
    if (locationData == null) return NOWHERE;
    if (locationData is String) {
      final parts = locationData.split(',');
      if (parts.length == 2) {
        return GeoPoint(
          double.tryParse(parts[0].trim()) ?? 0.0,
          double.tryParse(parts[1].trim()) ?? 0.0,
        );
      }
    }
    return NOWHERE;
  }
}
