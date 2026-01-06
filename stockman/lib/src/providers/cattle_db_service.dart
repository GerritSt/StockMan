// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CattleDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  CattleDbService() {
    dlog('CattleDbService initialized with Supabase');
  }

  // Fetch all cattle for a specific camp
  Future<List<Cattle>> getCattle({
    required String farmId,
    required String campId,
  }) async {
    try {
      dlog('Fetching cattle for campId: $campId, farmId: $farmId');

      final cattleResponse = await _supabase
          .from('cattle')
          .select()
          .eq('camp_id', campId)
          .eq('farm_id', farmId);

      dlog('Fetched ${cattleResponse.length} cattle');

      return cattleResponse.map<Cattle>((cattleData) {
        return Cattle.fromJson(cattleData);
      }).toList();
    } catch (e) {
      dlog('Error fetching cattle: $e');
      return [];
    }
  }

  // Add a cattle entry to a specific camp
  Future<String> addCattle({
    required String farmId,
    required String campId,
    required Cattle cattle,
  }) async {
    try {
      final cattleData = cattle.toJson();
      cattleData['farm_id'] = farmId;
      cattleData['camp_id'] = campId;

      final response =
          await _supabase.from('cattle').insert(cattleData).select().single();

      final newId = response['id'] as String;
      dlog('Cattle added successfully with ID: $newId');
      return newId;
    } catch (e) {
      dlog('Error adding cattle: $e');
      rethrow;
    }
  }

  // Delete a cattle
  Future<void> deleteCattle({
    required String cattleId,
  }) async {
    try {
      await _supabase.from('cattle').delete().eq('id', cattleId);

      dlog('Cattle deleted successfully');
    } catch (e) {
      dlog('Error deleting cattle: $e');
      rethrow;
    }
  }

  // Update cattle status (e.g., mark as sold or dead)
  Future<void> updateCattleStatus({
    required String cattleId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('cattle')
          .update({'status': status}).eq('id', cattleId);

      dlog('Cattle status updated successfully to: $status');
    } catch (e) {
      dlog('Error updating cattle status: $e');
      rethrow;
    }
  }

  // Update cattle pregnancy status
  Future<void> updateCattlePregnancy({
    required String cattleId,
    required String pregnancy,
  }) async {
    try {
      await _supabase
          .from('cattle')
          .update({'pregnancy': pregnancy}).eq('id', cattleId);

      dlog('Cattle pregnancy status updated successfully to: $pregnancy');
    } catch (e) {
      dlog('Error updating cattle pregnancy: $e');
      rethrow;
    }
  }

  // Update cattle details
  Future<void> updateCattle({
    required String cattleId,
    required Cattle cattle,
  }) async {
    try {
      final cattleData = cattle.toJson();

      await _supabase.from('cattle').update(cattleData).eq('id', cattleId);

      dlog('Cattle updated successfully');
    } catch (e) {
      dlog('Error updating cattle: $e');
      rethrow;
    }
  }

  // Get a single cattle by ID
  Future<Cattle?> getCattleById(String cattleId) async {
    try {
      final response = await _supabase
          .from('cattle')
          .select()
          .eq('id', cattleId)
          .maybeSingle();

      if (response == null) {
        dlog('No cattle found with ID: $cattleId');
        return null;
      }

      return Cattle.fromJson(response);
    } catch (e) {
      dlog('Error fetching cattle by ID: $e');
      rethrow;
    }
  }
}
