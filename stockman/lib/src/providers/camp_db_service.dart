import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  CampDbService() {
    dlog('CampDbService initialized with Supabase');
  }

  /// Create a new camp for a farm
  Future<Camp> createCamp(String farmId, Camp camp) async {
    try {
      dlog('Creating camp: ${camp.name} for farm: $farmId');

      final response = await _supabase
          .from('camps')
          .insert({
            'farm_id': farmId,
            'name': camp.name,
            'location': '${camp.location.latitude},${camp.location.longitude}',
            'size': camp.size,
          })
          .select()
          .single();

      dlog('Camp created successfully with id: ${response['id']}');

      return Camp(
        id: response['id'],
        name: response['name'],
        location: _parseGeoPoint(response['location']),
        size: camp.size, // Not stored in DB, kept in memory
      );
    } catch (e) {
      dlog('Error creating camp: $e');
      rethrow;
    }
  }

  /// Update an existing camp
  Future<Camp> updateCamp(Camp camp) async {
    try {
      dlog('Updating camp: ${camp.id}');

      final response = await _supabase
          .from('camps')
          .update({
            'name': camp.name,
            'location': '${camp.location.latitude},${camp.location.longitude}',
            'size': camp.size,
          })
          .eq('id', camp.id)
          .select()
          .single();

      dlog('Camp updated successfully');

      return Camp(
        id: response['id'],
        name: response['name'],
        location: _parseGeoPoint(response['location']),
        size: response['size'] ?? 0,
      );
    } catch (e) {
      dlog('Error updating camp: $e');
      rethrow;
    }
  }

  /// Delete a camp and all associated cattle
  Future<void> deleteCamp(String campId) async {
    try {
      dlog('Deleting camp: $campId');

      // Note: You may want to update cattle.camp_id to null instead of deleting
      // For now, we just delete the camp (cattle will have null camp_id)
      await _supabase.from('camps').delete().eq('id', campId);

      dlog('Camp deleted successfully');
    } catch (e) {
      dlog('Error deleting camp: $e');
      rethrow;
    }
  }

  /// Get a single camp by ID
  Future<Camp?> getCamp(String campId) async {
    try {
      dlog('Fetching camp: $campId');

      final response =
          await _supabase.from('camps').select().eq('id', campId).maybeSingle();

      if (response == null) {
        dlog('Camp not found');
        return null;
      }

      return Camp(
        id: response['id'],
        name: response['name'],
        location: _parseGeoPoint(response['location']),
        size: response['size'] ?? 0,
      );
    } catch (e) {
      dlog('Error fetching camp: $e');
      rethrow;
    }
  }

  /// Get all camps for a farm
  Future<List<Camp>> getCamps(String farmId) async {
    try {
      dlog('Fetching camps for farm: $farmId');

      final campsResponse = await _supabase
          .from('camps')
          .select()
          .eq('farm_id', farmId)
          .order('created_at', ascending: false);

      List<Camp> camps = campsResponse.map<Camp>((campData) {
        return Camp(
          id: campData['id'],
          name: campData['name'],
          location: _parseGeoPoint(campData['location']),
          size: campData['size'] ?? 0,
        );
      }).toList();

      dlog('Fetched ${camps.length} camps');
      return camps;
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
