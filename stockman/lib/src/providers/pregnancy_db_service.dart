import 'package:stockman/src/models/pregnancy.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PregnancyDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  PregnancyDbService() {
    dlog('PregnancyDbService initialized with Supabase');
  }

  // Fetch all pregnancy records for a specific cattle
  Future<List<Pregnancy>> getPregnancies({
    required String cattleId,
  }) async {
    try {
      dlog('Fetching pregnancies for cattleId: $cattleId');

      final response = await _supabase
          .from('pregnancies')
          .select()
          .eq('cattle_id', cattleId)
          .order('conception_date', ascending: false);

      dlog('Fetched ${response.length} pregnancy records');

      return response.map<Pregnancy>((data) {
        return Pregnancy.fromJson(data);
      }).toList();
    } catch (e) {
      dlog('Error fetching pregnancies: $e');
      return [];
    }
  }

  // Get a single pregnancy by ID
  Future<Pregnancy?> getPregnancyById(String pregnancyId) async {
    try {
      final response = await _supabase
          .from('pregnancies')
          .select()
          .eq('id', pregnancyId)
          .maybeSingle();

      if (response == null) {
        dlog('No pregnancy found with ID: $pregnancyId');
        return null;
      }

      return Pregnancy.fromJson(response);
    } catch (e) {
      dlog('Error fetching pregnancy by ID: $e');
      return null;
    }
  }

  // Add a pregnancy record
  Future<String> addPregnancy({
    required Pregnancy pregnancy,
  }) async {
    try {
      final data = pregnancy.toJson();

      final response =
          await _supabase.from('pregnancies').insert(data).select().single();

      final newId = response['id'] as String;
      dlog('Pregnancy record added successfully with ID: $newId');
      return newId;
    } catch (e) {
      dlog('Error adding pregnancy: $e');
      rethrow;
    }
  }

  // Update a pregnancy record
  Future<void> updatePregnancy({
    required String pregnancyId,
    required Pregnancy pregnancy,
  }) async {
    try {
      final data = pregnancy.toJson();

      await _supabase
          .from('pregnancies')
          .update(data)
          .eq('id', pregnancyId);

      dlog('Pregnancy updated successfully');
    } catch (e) {
      dlog('Error updating pregnancy: $e');
      rethrow;
    }
  }

  // Update pregnancy status
  Future<void> updatePregnancyStatus({
    required String pregnancyId,
    required String status,
    DateTime? endDate,
  }) async {
    try {
      final updateData = {
        'pregnancy_status': status,
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
      };

      await _supabase
          .from('pregnancies')
          .update(updateData)
          .eq('id', pregnancyId);

      dlog('Pregnancy status updated successfully to: $status');
    } catch (e) {
      dlog('Error updating pregnancy status: $e');
      rethrow;
    }
  }

  // Delete a pregnancy record
  Future<void> deletePregnancy({
    required String pregnancyId,
  }) async {
    try {
      await _supabase.from('pregnancies').delete().eq('id', pregnancyId);

      dlog('Pregnancy deleted successfully');
    } catch (e) {
      dlog('Error deleting pregnancy: $e');
      rethrow;
    }
  }

  // Get active pregnancy for a cattle (pregnancy not yet ended)
  Future<Pregnancy?> getActivePregnancy({
    required String cattleId,
  }) async {
    try {
      final response = await _supabase
          .from('pregnancies')
          .select()
          .eq('cattle_id', cattleId)
          .isFilter('end_date', null)
          .order('conception_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Pregnancy.fromJson(response);
    } catch (e) {
      dlog('Error fetching active pregnancy: $e');
      return null;
    }
  }
}
