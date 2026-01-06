import 'package:stockman/src/models/treatment_log.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TreatmentLogDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  TreatmentLogDbService() {
    dlog('TreatmentLogDbService initialized with Supabase');
  }

  // Fetch all treatment logs for a specific cattle
  Future<List<TreatmentLog>> getTreatmentLogs({
    required String cattleId,
  }) async {
    try {
      dlog('Fetching treatment logs for cattleId: $cattleId');

      final response = await _supabase
          .from('treatment_logs')
          .select()
          .eq('cattle_id', cattleId)
          .order('date', ascending: false);

      dlog('Fetched ${response.length} treatment logs');

      return response.map<TreatmentLog>((data) {
        return TreatmentLog.fromJson(data);
      }).toList();
    } catch (e) {
      dlog('Error fetching treatment logs: $e');
      return [];
    }
  }

  // Add a treatment log entry
  Future<String> addTreatmentLog({
    required TreatmentLog treatmentLog,
  }) async {
    try {
      final data = treatmentLog.toJson();

      final response =
          await _supabase.from('treatment_logs').insert(data).select().single();

      final newId = response['id'] as String;
      dlog('Treatment log added successfully with ID: $newId');
      return newId;
    } catch (e) {
      dlog('Error adding treatment log: $e');
      rethrow;
    }
  }

  // Delete a treatment log
  Future<void> deleteTreatmentLog({
    required String treatmentLogId,
  }) async {
    try {
      await _supabase.from('treatment_logs').delete().eq('id', treatmentLogId);

      dlog('Treatment log deleted successfully');
    } catch (e) {
      dlog('Error deleting treatment log: $e');
      rethrow;
    }
  }

  // Update a treatment log
  Future<void> updateTreatmentLog({
    required String treatmentLogId,
    required TreatmentLog treatmentLog,
  }) async {
    try {
      final data = treatmentLog.toJson();

      await _supabase
          .from('treatment_logs')
          .update(data)
          .eq('id', treatmentLogId);

      dlog('Treatment log updated successfully');
    } catch (e) {
      dlog('Error updating treatment log: $e');
      rethrow;
    }
  }

  // Get recent treatments for a cattle (last N treatments)
  Future<List<TreatmentLog>> getRecentTreatments({
    required String cattleId,
    int limit = 5,
  }) async {
    try {
      final response = await _supabase
          .from('treatment_logs')
          .select()
          .eq('cattle_id', cattleId)
          .order('date', ascending: false)
          .limit(limit);

      return response.map<TreatmentLog>((data) {
        return TreatmentLog.fromJson(data);
      }).toList();
    } catch (e) {
      dlog('Error fetching recent treatments: $e');
      rethrow;
    }
  }
}
