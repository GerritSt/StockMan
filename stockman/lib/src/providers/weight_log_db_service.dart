import 'package:stockman/src/models/weight_log.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeightLogDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  WeightLogDbService() {
    dlog('WeightLogDbService initialized with Supabase');
  }

  // Fetch all weight logs for a specific cattle
  Future<List<WeightLog>> getWeightLogs({
    required String cattleId,
  }) async {
    try {
      dlog('Fetching weight logs for cattleId: $cattleId');

      final response = await _supabase
          .from('weight_logs')
          .select()
          .eq('cattle_id', cattleId)
          .order('date', ascending: true);

      dlog('Fetched ${response.length} weight logs');

      return response.map<WeightLog>((data) {
        return WeightLog.fromJson(data);
      }).toList();
    } catch (e) {
      dlog('Error fetching weight logs: $e');
      return [];
    }
  }

  // Add a weight log entry
  Future<String> addWeightLog({
    required WeightLog weightLog,
  }) async {
    try {
      final data = weightLog.toJson();

      final response =
          await _supabase.from('weight_logs').insert(data).select().single();

      final newId = response['id'] as String;
      dlog('Weight log added successfully with ID: $newId');
      return newId;
    } catch (e) {
      dlog('Error adding weight log: $e');
      rethrow;
    }
  }

  // Delete a weight log
  Future<void> deleteWeightLog({
    required String weightLogId,
  }) async {
    try {
      await _supabase.from('weight_logs').delete().eq('id', weightLogId);

      dlog('Weight log deleted successfully');
    } catch (e) {
      dlog('Error deleting weight log: $e');
      rethrow;
    }
  }

  // Update a weight log
  Future<void> updateWeightLog({
    required String weightLogId,
    required WeightLog weightLog,
  }) async {
    try {
      final data = weightLog.toJson();

      await _supabase.from('weight_logs').update(data).eq('id', weightLogId);

      dlog('Weight log updated successfully');
    } catch (e) {
      dlog('Error updating weight log: $e');
      rethrow;
    }
  }

  // Get the latest weight for a cattle
  Future<WeightLog?> getLatestWeight({
    required String cattleId,
  }) async {
    try {
      final response = await _supabase
          .from('weight_logs')
          .select()
          .eq('cattle_id', cattleId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        dlog('No weight logs found for cattle: $cattleId');
        return null;
      }

      return WeightLog.fromJson(response);
    } catch (e) {
      dlog('Error fetching latest weight: $e');
      rethrow;
    }
  }
}
