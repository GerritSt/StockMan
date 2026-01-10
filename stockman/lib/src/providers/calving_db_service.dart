import 'package:stockman/src/models/calving.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalvingDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  CalvingDbService() {
    dlog('CalvingDbService initialized with Supabase');
  }

  // Fetch all calving records for a specific cow
  Future<List<Calving>> getCalvings({
    required String cowId,
  }) async {
    try {
      dlog('Fetching calvings for cowId: $cowId');

      final response = await _supabase
          .from('calvings')
          .select()
          .eq('cow_id', cowId)
          .order('calving_date', ascending: false);

      dlog('Fetched ${response.length} calving records');

      return response.map<Calving>((data) {
        return Calving.fromJson(data);
      }).toList();
    } catch (e) {
      dlog('Error fetching calvings: $e');
      return [];
    }
  }

  // Get calving records by pregnancy ID
  Future<Calving?> getCalvingByPregnancyId(String pregnancyId) async {
    try {
      final response = await _supabase
          .from('calvings')
          .select()
          .eq('pregnancy_id', pregnancyId)
          .maybeSingle();

      if (response == null) {
        dlog('No calving found for pregnancy ID: $pregnancyId');
        return null;
      }

      return Calving.fromJson(response);
    } catch (e) {
      dlog('Error fetching calving by pregnancy ID: $e');
      return null;
    }
  }

  // Get a single calving by ID
  Future<Calving?> getCalvingById(String calvingId) async {
    try {
      final response = await _supabase
          .from('calvings')
          .select()
          .eq('id', calvingId)
          .maybeSingle();

      if (response == null) {
        dlog('No calving found with ID: $calvingId');
        return null;
      }

      return Calving.fromJson(response);
    } catch (e) {
      dlog('Error fetching calving by ID: $e');
      return null;
    }
  }

  // Add a calving record
  Future<String> addCalving({
    required Calving calving,
  }) async {
    try {
      final data = calving.toJson();

      final response =
          await _supabase.from('calvings').insert(data).select().single();

      final newId = response['id'] as String;
      dlog('Calving record added successfully with ID: $newId');
      return newId;
    } catch (e) {
      dlog('Error adding calving: $e');
      rethrow;
    }
  }

  // Update a calving record
  Future<void> updateCalving({
    required String calvingId,
    required Calving calving,
  }) async {
    try {
      final data = calving.toJson();

      await _supabase.from('calvings').update(data).eq('id', calvingId);

      dlog('Calving updated successfully');
    } catch (e) {
      dlog('Error updating calving: $e');
      rethrow;
    }
  }

  // Link a calf to a calving record
  Future<void> linkCalfToCalving({
    required String calvingId,
    required String calfId,
  }) async {
    try {
      await _supabase
          .from('calvings')
          .update({'calf_id': calfId}).eq('id', calvingId);

      dlog('Calf linked to calving successfully');
    } catch (e) {
      dlog('Error linking calf to calving: $e');
      rethrow;
    }
  }

  // Delete a calving record
  Future<void> deleteCalving({
    required String calvingId,
  }) async {
    try {
      await _supabase.from('calvings').delete().eq('id', calvingId);

      dlog('Calving deleted successfully');
    } catch (e) {
      dlog('Error deleting calving: $e');
      rethrow;
    }
  }

  // Get all calves born from a specific cow
  Future<List<String>> getCalfIdsByCow({
    required String cowId,
  }) async {
    try {
      final response = await _supabase
          .from('calvings')
          .select('calf_id')
          .eq('cow_id', cowId)
          .not('calf_id', 'is', null);

      return response.map<String>((data) => data['calf_id'] as String).toList();
    } catch (e) {
      dlog('Error fetching calf IDs: $e');
      return [];
    }
  }
}
