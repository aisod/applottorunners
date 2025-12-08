import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

/// Service to manage immediate errand requests that are waiting for runner acceptance
/// These errands are stored temporarily until a runner accepts them
class ImmediateErrandService {
  static const String _pendingErrandsKey = 'pending_immediate_errands';

  /// Store an immediate errand request temporarily in database with pending status
  static Future<Map<String, dynamic>> storePendingErrand(
      Map<String, dynamic> errandData) async {
    try {
      // Remove fields that shouldn't be stored in database
      final cleanData = Map<String, dynamic>.from(errandData);
      cleanData.remove('id'); // Remove pending ID, let database generate UUID
      cleanData
          .remove('customer'); // Remove customer object, only store customer_id

      final pendingData = {
        ...cleanData,
        'status':
            'posted', // Use 'posted' status so runners can see immediate requests
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Store in database with pending status
      final response = await SupabaseConfig.client
          .from('errands')
          .insert(pendingData)
          .select()
          .single();

      print(
          '📝 Stored pending immediate errand in database: ${errandData['title']} with ID: ${response['id']}');

      // Store the database ID in SharedPreferences for tracking
      final prefs = await SharedPreferences.getInstance();
      final pendingIds = prefs.getStringList('pending_errand_ids') ?? [];
      pendingIds.add(response['id']);
      await prefs.setStringList('pending_errand_ids', pendingIds);

      return response;
    } catch (e) {
      print('❌ Error storing pending errand: $e');
      throw Exception('Failed to store pending errand: $e');
    }
  }

  /// Get all pending immediate errands from database
  static Future<List<Map<String, dynamic>>> getPendingErrands() async {
    try {
      // Query database for errands with posted status (immediate requests)
      final response = await SupabaseConfig.client
          .from('errands')
          .select('''
            *,
            customer:customer_id(full_name, phone)
          ''')
          .eq('status', 'posted')
          .eq('is_immediate', true) // Only get immediate requests
          .filter('runner_id', 'is', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting pending errands: $e');
      return [];
    }
  }

  /// Remove a pending errand (when accepted or cancelled)
  static Future<void> removePendingErrand(String errandId) async {
    try {
      // Update the errand status to accepted (this is handled by createAcceptedErrand)
      // Just remove from SharedPreferences tracking
      final prefs = await SharedPreferences.getInstance();
      final pendingIds = prefs.getStringList('pending_errand_ids') ?? [];
      pendingIds.remove(errandId);
      await prefs.setStringList('pending_errand_ids', pendingIds);

      print('🗑️ Removed pending errand from tracking: $errandId');
    } catch (e) {
      print('❌ Error removing pending errand: $e');
    }
  }

  /// Clear all pending errands (for cleanup)
  static Future<void> clearAllPendingErrands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingErrandsKey);
      print('🧹 Cleared all pending errands');
    } catch (e) {
      print('❌ Error clearing pending errands: $e');
    }
  }

  /// Clean up expired immediate errands (older than 30 seconds)
  /// This function actually deletes expired errands from the database
  static Future<void> cleanupExpiredErrands() async {
    try {
      final now = DateTime.now();
      final expiredCutoff = now.subtract(const Duration(seconds: 30));

      // Delete expired immediate errands from database
      await SupabaseConfig.client
          .from('errands')
          .delete()
          .eq('status', 'posted')
          .eq('is_immediate', true)
          .filter('runner_id', 'is', null)
          .lt('created_at', expiredCutoff.toIso8601String());

      print('🧹 Deleted expired immediate errands from database');
    } catch (e) {
      print('❌ Error cleaning up expired errands: $e');
    }
  }

  /// Generate a unique ID for pending errands
  static String generatePendingErrandId() {
    return 'pending_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }
}
