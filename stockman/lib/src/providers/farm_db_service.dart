import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  FarmDbService() {
    dlog('FarmDbService initialized with Supabase');
  }

  /// Create a new farm for a farmer
  Future<Farm> createFarm(String farmerId, Farm farm) async {
    try {
      dlog('Creating farm: ${farm.name} for farmer: $farmerId');

      final response = await _supabase
          .from('farms')
          .insert({
            'farmer_id': farmerId,
            'name': farm.name,
            'location': '${farm.location.latitude},${farm.location.longitude}',
            'type': farm.type,
            'size': farm.size,
          })
          .select()
          .single();

      dlog('Farm created successfully with id: ${response['id']}');

      return Farm(
        id: response['id'],
        name: response['name'],
        location: _parseGeoPoint(response['location']),
        type: response['type'] ?? 'Cattle',
        size: response['size'] ?? 0,
        camps: [],
        cattle: [],
      );
    } catch (e) {
      dlog('Error creating farm: $e');
      rethrow;
    }
  }

  /// Update an existing farm
  Future<Farm> updateFarm(Farm farm) async {
    try {
      dlog('Updating farm: ${farm.id}');

      final response = await _supabase
          .from('farms')
          .update({
            'name': farm.name,
            'location': '${farm.location.latitude},${farm.location.longitude}',
            'type': farm.type,
            'size': farm.size,
          })
          .eq('id', farm.id)
          .select()
          .single();

      dlog('Farm updated successfully');

      return Farm(
        id: response['id'],
        name: response['name'],
        location: _parseGeoPoint(response['location']),
        type: response['type'] ?? 'Cattle',
        size: response['size'] ?? 0,
        camps: farm.camps,
        cattle: farm.cattle,
      );
    } catch (e) {
      dlog('Error updating farm: $e');
      rethrow;
    }
  }

  /// Delete a farm and all associated camps and cattle
  Future<void> deleteFarm(String farmId) async {
    try {
      dlog('Deleting farm: $farmId');

      // Supabase will cascade delete camps and cattle due to foreign key constraints
      await _supabase.from('farms').delete().eq('id', farmId);

      dlog('Farm deleted successfully');
    } catch (e) {
      dlog('Error deleting farm: $e');
      rethrow;
    }
  }

  /// Get a single farm by ID
  Future<Farm?> getFarm(String farmId) async {
    try {
      dlog('Fetching farm: $farmId');

      final response =
          await _supabase.from('farms').select().eq('id', farmId).maybeSingle();

      if (response == null) {
        dlog('Farm not found');
        return null;
      }

      // Fetch associated camps
      final camps = await _getCamps(farmId);

      return Farm(
        id: response['id'],
        name: response['name'],
        location: _parseGeoPoint(response['location']),
        type: response['type'] ?? 'Cattle',
        size: response['size'] ?? 0,
        camps: camps,
        cattle: [], // Cattle loaded separately if needed
      );
    } catch (e) {
      dlog('Error fetching farm: $e');
      rethrow;
    }
  }

  /// Get all farms for a farmer
  Future<List<Farm>> getFarms(String farmerId) async {
    try {
      dlog('Fetching farms for farmer: $farmerId');

      final farmsResponse = await _supabase
          .from('farms')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      List<Farm> farms = [];
      for (var farmData in farmsResponse) {
        final camps = await _getCamps(farmData['id']);

        farms.add(Farm(
          id: farmData['id'],
          name: farmData['name'],
          location: _parseGeoPoint(farmData['location']),
          type: farmData['type'] ?? 'Cattle',
          size: farmData['size'] ?? 0,
          camps: camps,
          cattle: [], // Cattle loaded separately if needed
        ));
      }

      dlog('Fetched ${farms.length} farms');
      return farms;
    } catch (e) {
      dlog('Error fetching farms: $e');
      return [];
    }
  }

  /// Get camps for a farm (private helper method)
  Future<List<Camp>> _getCamps(String farmId) async {
    try {
      final campsResponse = await _supabase
          .from('camps')
          .select()
          .eq('farm_id', farmId)
          .order('created_at', ascending: false);

      return campsResponse.map<Camp>((campData) {
        return Camp(
          id: campData['id'],
          name: campData['name'],
          location: _parseGeoPoint(campData['location']),
          size: 0, // Not in database schema
        );
      }).toList();
    } catch (e) {
      dlog('Error fetching camps: $e');
      return [];
    }
  }

  /// Helper method to parse GeoPoint from string
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
