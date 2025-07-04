import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseConfig {
  static const String supabaseUrl = "https://irfbqpruvkkbylwwikwx.supabase.co";
  static const String anonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlyZmJxcHJ1dmtrYnlsd3dpa3d4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExMTk2NzEsImV4cCI6MjA2NjY5NTY3MX0.56qf3WDEWSlWH1iq5dBHNgsq1QFA82eGtgBeCBcxCdo";

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
    );
  }

  // Authentication helpers
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<AuthResponse> signInWithEmail(
      String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  static Future<AuthResponse> signUpWithEmail(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      return response;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Database helpers
  static Future<List<Map<String, dynamic>>> getErrands({String? status}) async {
    try {
      var query = client.from('errands').select('''
        *,
        customer:customer_id(full_name, phone),
        runner:runner_id(full_name, phone)
      ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      final result = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to fetch errands: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getMyErrands(String userId) async {
    try {
      final result = await client
          .from('errands')
          .select('''
        *,
        customer:customer_id(full_name, phone),
        runner:runner_id(full_name, phone)
      ''')
          .or('customer_id.eq.$userId,runner_id.eq.$userId')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to fetch my errands: $e');
    }
  }

  static Future<Map<String, dynamic>> createErrand(
      Map<String, dynamic> errandData) async {
    try {
      final response =
          await client.from('errands').insert(errandData).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to create errand: $e');
    }
  }

  static Future<void> updateErrandStatus(String errandId, String status) async {
    try {
      await client.from('errands').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);
    } catch (e) {
      throw Exception('Failed to update errand status: $e');
    }
  }

  static Future<void> acceptErrand(String errandId, String runnerId) async {
    try {
      await client.from('errands').update({
        'runner_id': runnerId,
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);
    } catch (e) {
      throw Exception('Failed to accept errand: $e');
    }
  }

  // User profile helpers
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('users').select().eq('id', userId).maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (currentUser == null) return null;
    return getUserProfile(currentUser!.id);
  }

  static Future<void> createUserProfile(Map<String, dynamic> userData) async {
    try {
      await client.from('users').insert(userData);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  static Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUser == null) return false;

    try {
      await client.from('users').update(updates).eq('id', currentUser!.id);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Runner application helpers
  static Future<void> submitRunnerApplication(
      Map<String, dynamic> applicationData) async {
    try {
      await client.from('runner_applications').insert(applicationData);
    } catch (e) {
      throw Exception('Failed to submit runner application: $e');
    }
  }

  static Future<Map<String, dynamic>?> getRunnerApplication(
      String userId) async {
    try {
      final response = await client
          .from('runner_applications')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch runner application: $e');
    }
  }

  // Storage helpers
  static Future<String> uploadImage(
      String bucket, String path, Uint8List bytes) async {
    try {
      // Check if file already exists and remove it
      try {
        await client.storage.from(bucket).remove([path]);
      } catch (e) {
        // File doesn't exist, which is fine
      }

      // Upload the new file
      await client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get the public URL
      final url = client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<String?> uploadProfileImage(
      String filePath, List<int> fileBytes) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final fileExt = filePath.split('.').last.toLowerCase();
      final fileName = '${user.id}.$fileExt';

      await client.storage.from('profiles').uploadBinary(
            fileName,
            Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final imageUrl = client.storage.from('profiles').getPublicUrl(fileName);

      await updateUserProfile({'avatar_url': imageUrl});

      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Admin helpers
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllErrands() async {
    try {
      final response = await client.from('errands').select('''
          *,
          customer:customer_id(full_name, email),
          runner:runner_id(full_name, email)
        ''').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch errands: $e');
    }
  }

  static Future<List<Map<String, dynamic>>>
      getPendingRunnerApplications() async {
    try {
      final response = await client
          .from('runner_applications')
          .select('''
          *,
          user:user_id(full_name, email, phone)
        ''')
          .eq('verification_status', 'pending')
          .order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch pending applications: $e');
    }
  }

  static Future<void> updateRunnerApplicationStatus(
      String applicationId, String status, String? notes) async {
    try {
      await client.from('runner_applications').update({
        'verification_status': status,
        'notes': notes,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': currentUser?.id,
      }).eq('id', applicationId);
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllPayments() async {
    try {
      final response = await client.from('payments').select('''
          *,
          errand:errand_id(title, category),
          customer:customer_id(full_name, email),
          runner:runner_id(full_name, email)
        ''').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  static Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      // Get counts and metrics
      final usersResponse = await client.from('users').select('id');
      final errandsResponse = await client.from('errands').select('id');
      final completedErrandsResponse =
          await client.from('errands').select('id').eq('status', 'completed');
      final totalRevenue = await client
          .from('payments')
          .select('amount')
          .eq('status', 'completed');

      // Calculate revenue
      double revenue = 0;
      for (var payment in totalRevenue) {
        revenue += (payment['amount'] as num).toDouble();
      }

      return {
        'total_users': usersResponse.length,
        'total_errands': errandsResponse.length,
        'completed_errands': completedErrandsResponse.length,
        'total_revenue': revenue,
      };
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  static Future<void> deactivateUser(String userId) async {
    try {
      await client.from('users').update({
        'is_verified': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  // ==========================================
  // ADMIN SERVICE MANAGEMENT FUNCTIONS
  // ==========================================

  // Services management
  static Future<List<Map<String, dynamic>>> getAllServices() async {
    try {
      final response = await client.from('services').select('''
          *,
          service_pricing_tiers(*)
        ''').order('category').order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveServices() async {
    try {
      final response = await client
          .from('services')
          .select('''
          *,
          service_pricing_tiers!inner(*)
        ''')
          .eq('is_active', true)
          .eq('service_pricing_tiers.is_active', true)
          .order('category')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch active services: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final response = await client
          .from('services')
          .select()
          .eq('is_active', true)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getServicesByCategory(
      String category) async {
    try {
      final response = await client
          .from('services')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch services by category: $e');
    }
  }

  static Future<Map<String, dynamic>> createService(
      Map<String, dynamic> serviceData) async {
    try {
      final response = await client
          .from('services')
          .insert({
            ...serviceData,
            'created_by': currentUser?.id,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  static Future<bool> updateService(
      String serviceId, Map<String, dynamic> updates) async {
    try {
      await client.from('services').update(updates).eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  static Future<bool> deleteService(String serviceId) async {
    try {
      await client
          .from('services')
          .update({'is_active': false}).eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  // Service pricing tiers management
  static Future<List<Map<String, dynamic>>> getServicePricingTiers(
      String serviceId) async {
    try {
      final response = await client
          .from('service_pricing_tiers')
          .select()
          .eq('service_id', serviceId)
          .eq('is_active', true)
          .order('price_multiplier');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch pricing tiers: $e');
    }
  }

  static Future<Map<String, dynamic>> createPricingTier(
      Map<String, dynamic> tierData) async {
    try {
      final response = await client
          .from('service_pricing_tiers')
          .insert(tierData)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create pricing tier: $e');
    }
  }

  static Future<void> updatePricingTier(
      String tierId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('service_pricing_tiers')
          .update(updates)
          .eq('id', tierId);
    } catch (e) {
      throw Exception('Failed to update pricing tier: $e');
    }
  }

  static Future<void> deletePricingTier(String tierId) async {
    try {
      await client
          .from('service_pricing_tiers')
          .update({'is_active': false}).eq('id', tierId);
    } catch (e) {
      throw Exception('Failed to delete pricing tier: $e');
    }
  }

  // Admin settings management
  static Future<List<Map<String, dynamic>>> getAdminSettings() async {
    try {
      final response =
          await client.from('admin_settings').select().order('setting_key');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch admin settings: $e');
    }
  }

  static Future<Map<String, dynamic>?> getAdminSetting(String key) async {
    try {
      final response = await client
          .from('admin_settings')
          .select()
          .eq('setting_key', key)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch admin setting: $e');
    }
  }

  static Future<void> updateAdminSetting(String key, String value) async {
    try {
      await client.from('admin_settings').upsert({
        'setting_key': key,
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update admin setting: $e');
    }
  }

  // User role management
  static Future<bool> isAdmin(String? userId) async {
    if (userId == null) return false;
    try {
      final user = await getUserProfile(userId);
      return user?['user_type'] == 'admin' ||
          user?['user_type'] == 'super_admin';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isSuperAdmin(String? userId) async {
    if (userId == null) return false;
    try {
      final user = await getUserProfile(userId);
      return user?['user_type'] == 'super_admin';
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await client.from('users').update({
        'user_type': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Calculate service pricing
  static double calculateServicePrice(
      Map<String, dynamic> service, Map<String, dynamic>? pricingTier,
      {double hours = 1.0, double miles = 0.0}) {
    double basePrice = (service['base_price'] as num).toDouble();
    double pricePerHour = (service['price_per_hour'] as num? ?? 0).toDouble();
    double pricePerMile = (service['price_per_mile'] as num? ?? 0).toDouble();

    double totalPrice =
        basePrice + (pricePerHour * hours) + (pricePerMile * miles);

    if (pricingTier != null) {
      double multiplier =
          (pricingTier['price_multiplier'] as num? ?? 1.0).toDouble();
      totalPrice *= multiplier;
    }

    return totalPrice;
  }

  // ==========================================
  // TRANSPORTATION SYSTEM MANAGEMENT
  // ==========================================

  // Category Management
  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await client
          .from('service_categories')
          .select()
          .order('display_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  static Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> categoryData) async {
    try {
      final response = await client
          .from('service_categories')
          .insert({
            ...categoryData,
            'created_by': currentUser?.id,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  static Future<void> updateCategory(
      String categoryId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('service_categories')
          .update(updates)
          .eq('id', categoryId);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  static Future<void> deleteCategory(String categoryId) async {
    try {
      await client
          .from('service_categories')
          .update({'is_active': false}).eq('id', categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Vehicle Types Management
  static Future<List<Map<String, dynamic>>> getAllVehicleTypes() async {
    try {
      final response = await client
          .from('vehicle_types')
          .select()
          .eq('is_active', true)
          .order('capacity');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch vehicle types: $e');
    }
  }

  static Future<Map<String, dynamic>> createVehicleType(
      Map<String, dynamic> vehicleData) async {
    try {
      final response = await client
          .from('vehicle_types')
          .insert(vehicleData)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create vehicle type: $e');
    }
  }

  static Future<void> updateVehicleType(
      String vehicleId, Map<String, dynamic> updates) async {
    try {
      await client.from('vehicle_types').update(updates).eq('id', vehicleId);
    } catch (e) {
      throw Exception('Failed to update vehicle type: $e');
    }
  }

  static Future<void> deleteVehicleType(String vehicleId) async {
    try {
      await client
          .from('vehicle_types')
          .update({'is_active': false}).eq('id', vehicleId);
    } catch (e) {
      throw Exception('Failed to delete vehicle type: $e');
    }
  }

  // Routes Management
  static Future<List<Map<String, dynamic>>> getServiceRoutes(
      String serviceId) async {
    try {
      final response = await client.from('transportation_services').select('''
          *,
          route:routes(*, origin_town:towns!origin_town_id(name), destination_town:towns!destination_town_id(name)),
          service_schedules(*),
          service_pricing(*, vehicle_types(*))
        ''').eq('id', serviceId).eq('is_active', true).order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch service routes: $e');
    }
  }

  static Future<Map<String, dynamic>> createRoute(
      Map<String, dynamic> routeData) async {
    try {
      final response =
          await client.from('routes').insert(routeData).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to create route: $e');
    }
  }

  static Future<void> updateRoute(
      String routeId, Map<String, dynamic> updates) async {
    try {
      await client.from('routes').update(updates).eq('id', routeId);
    } catch (e) {
      throw Exception('Failed to update route: $e');
    }
  }

  static Future<void> deleteRoute(String routeId) async {
    try {
      await client
          .from('routes')
          .update({'is_active': false}).eq('id', routeId);
    } catch (e) {
      throw Exception('Failed to delete route: $e');
    }
  }

  // Schedules Management
  static Future<List<Map<String, dynamic>>> getRouteSchedules(
      String routeId) async {
    try {
      final response = await client
          .from('service_schedules')
          .select()
          .eq('route_id', routeId)
          .eq('is_active', true)
          .order('departure_time');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch route schedules: $e');
    }
  }

  static Future<Map<String, dynamic>> createSchedule(
      Map<String, dynamic> scheduleData) async {
    try {
      final response = await client
          .from('service_schedules')
          .insert(scheduleData)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  static Future<void> updateSchedule(
      String scheduleId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('service_schedules')
          .update(updates)
          .eq('id', scheduleId);
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  static Future<void> deleteSchedule(String scheduleId) async {
    try {
      await client
          .from('service_schedules')
          .update({'is_active': false}).eq('id', scheduleId);
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  // Route Pricing Management
  static Future<List<Map<String, dynamic>>> getRoutePricing(
      String routeId) async {
    try {
      final response = await client
          .from('service_pricing')
          .select('''
          *,
          service:transportation_services(*, route:routes(*)),
          vehicle_types(*)
        ''')
          .eq('service.route_id', routeId)
          .eq('is_active', true)
          .order('base_price');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch route pricing: $e');
    }
  }

  static Future<Map<String, dynamic>> createRoutePricing(
      Map<String, dynamic> pricingData) async {
    try {
      final response = await client
          .from('service_pricing')
          .insert(pricingData)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create route pricing: $e');
    }
  }

  static Future<void> updateRoutePricing(
      String pricingId, Map<String, dynamic> updates) async {
    try {
      await client.from('service_pricing').update(updates).eq('id', pricingId);
    } catch (e) {
      throw Exception('Failed to update route pricing: $e');
    }
  }

  static Future<void> deleteRoutePricing(String pricingId) async {
    try {
      await client
          .from('service_pricing')
          .update({'is_active': false}).eq('id', pricingId);
    } catch (e) {
      throw Exception('Failed to delete route pricing: $e');
    }
  }

  // Transportation Search & Booking (for users)
  static Future<List<Map<String, dynamic>>> searchTransportation({
    String? fromLocation,
    String? toLocation,
    String? serviceType,
  }) async {
    try {
      var query = client.from('transportation_services').select('''
          *,
          route:routes(*, origin_town:towns!origin_town_id(name), destination_town:towns!destination_town_id(name)),
          service_schedules(*),
          service_pricing(*, vehicle_types(*))
        ''').eq('is_active', true);

      if (fromLocation != null) {
        query = query.ilike('route.origin_town.name', '%$fromLocation%');
      }
      if (toLocation != null) {
        query = query.ilike('route.destination_town.name', '%$toLocation%');
      }

      final response = await query.order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search transportation: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableRoutes() async {
    try {
      final response = await client.from('transportation_services').select('''
          *,
          route:routes(*, origin_town:towns!origin_town_id(name), destination_town:towns!destination_town_id(name)),
          service_schedules(*),
          service_pricing(base_price, pickup_fee, vehicle_types(name, capacity))
        ''').eq('is_active', true).order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch available routes: $e');
    }
  }

  // Transportation Booking
  static Future<Map<String, dynamic>> bookTransportation({
    required String routeId,
    required String scheduleId,
    required String vehicleTypeId,
    required String pricingId,
    required bool includePickup,
    String? pickupAddress,
    String? passengerName,
    String? passengerPhone,
    int passengerCount = 1,
  }) async {
    try {
      // This would create an errand with transportation-specific details
      final errandData = {
        'customer_id': currentUser?.id,
        'category': 'transportation',
        'title': 'Transportation Booking',
        'description': 'Transportation service booking',
        'pickup_location': pickupAddress ?? 'To be determined',
        'delivery_location': 'Transportation service',
        'status': 'pending',
        'transportation_details': {
          'route_id': routeId,
          'schedule_id': scheduleId,
          'vehicle_type_id': vehicleTypeId,
          'pricing_id': pricingId,
          'include_pickup': includePickup,
          'passenger_count': passengerCount,
          'passenger_name': passengerName,
          'passenger_phone': passengerPhone,
        },
      };

      final response =
          await client.from('errands').insert(errandData).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to book transportation: $e');
    }
  }

  // ============= NEW TRANSPORTATION SYSTEM METHODS =============

  // Service Categories Management
  static Future<List<Map<String, dynamic>>> getServiceCategories() async {
    final response = await client
        .from('service_categories')
        .select()
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getServiceSubcategories(
      [String? categoryId]) async {
    var query = client
        .from('service_subcategories')
        .select('*, service_categories(name)')
        .eq('is_active', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query.order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServiceCategory(
      Map<String, dynamic> categoryData) async {
    try {
      final response = await client
          .from('service_categories')
          .insert(categoryData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service category: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createServiceSubcategory(
      Map<String, dynamic> subcategoryData) async {
    try {
      final response = await client
          .from('service_subcategories')
          .insert(subcategoryData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service subcategory: $e');
      return null;
    }
  }

  // Vehicle Types Management
  static Future<List<Map<String, dynamic>>> getVehicleTypes() async {
    final response = await client
        .from('vehicle_types')
        .select()
        .eq('is_active', true)
        .order('capacity');
    return List<Map<String, dynamic>>.from(response);
  }

  // Towns and Routes Management
  static Future<List<Map<String, dynamic>>> getTowns() async {
    final response =
        await client.from('towns').select().eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getRoutes() async {
    final response = await client.from('routes').select('''
          *,
          origin_town:towns!origin_town_id(name),
          destination_town:towns!destination_town_id(name)
        ''').eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Service Providers Management
  static Future<List<Map<String, dynamic>>> getServiceProviders() async {
    final response = await client
        .from('service_providers')
        .select()
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServiceProvider(
      Map<String, dynamic> providerData) async {
    try {
      final response = await client
          .from('service_providers')
          .insert(providerData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service provider: $e');
      return null;
    }
  }

  // Transportation Services Management
  static Future<List<Map<String, dynamic>>> getTransportationServices(
      [String? subcategoryId]) async {
    var query = client.from('transportation_services').select('''
          *,
          subcategory:service_subcategories(name, service_categories(name)),
          provider:service_providers(name),
          vehicle_type:vehicle_types(name, capacity),
          route:routes(name, origin_town:towns!origin_town_id(name), 
                     destination_town:towns!destination_town_id(name))
        ''').eq('is_active', true);

    if (subcategoryId != null) {
      query = query.eq('subcategory_id', subcategoryId);
    }

    final response = await query.order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createTransportationService(
      Map<String, dynamic> serviceData) async {
    try {
      final response = await client
          .from('transportation_services')
          .insert(serviceData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating transportation service: $e');
      return null;
    }
  }

  // Service Schedules Management
  static Future<List<Map<String, dynamic>>> getServiceSchedules(
      String serviceId) async {
    final response = await client
        .from('service_schedules')
        .select()
        .eq('service_id', serviceId)
        .eq('is_active', true)
        .order('departure_time');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServiceSchedule(
      Map<String, dynamic> scheduleData) async {
    try {
      final response = await client
          .from('service_schedules')
          .insert(scheduleData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service schedule: $e');
      return null;
    }
  }

  // Service Pricing Management
  static Future<List<Map<String, dynamic>>> getServicePricing(
      String serviceId) async {
    final response = await client
        .from('service_pricing')
        .select()
        .eq('service_id', serviceId)
        .eq('is_active', true)
        .order('effective_from');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServicePricing(
      Map<String, dynamic> pricingData) async {
    try {
      final response = await client
          .from('service_pricing')
          .insert(pricingData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service pricing: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getPricingTiers(
      String serviceId) async {
    final response = await client
        .from('pricing_tiers')
        .select()
        .eq('service_id', serviceId)
        .order('min_distance_km');
    return List<Map<String, dynamic>>.from(response);
  }

  // Transportation Bookings Management
  static Future<List<Map<String, dynamic>>> getUserBookings(
      [String? userId]) async {
    final user = client.auth.currentUser;
    final targetUserId = userId ?? user?.id;

    if (targetUserId == null) return [];

    final response = await client.from('transportation_bookings').select('''
          *,
          service:transportation_services(
            name,
            provider:service_providers(name),
            vehicle_type:vehicle_types(name, capacity),
            route:routes(name, origin_town:towns!origin_town_id(name), 
                       destination_town:towns!destination_town_id(name))
          ),
          schedule:service_schedules(departure_time, arrival_time)
        ''').eq('user_id', targetUserId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createTransportationBooking(
      Map<String, dynamic> bookingData) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      bookingData['user_id'] = user.id;

      final response = await client
          .from('transportation_bookings')
          .insert(bookingData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating transportation booking: $e');
      return null;
    }
  }

  static Future<bool> updateTransportationBooking(
      String bookingId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('transportation_bookings')
          .update(updates)
          .eq('id', bookingId);
      return true;
    } catch (e) {
      print('Error updating transportation booking: $e');
      return false;
    }
  }

  // Price calculation for transportation services
  static Future<Map<String, dynamic>?> calculateTransportationPrice({
    required String serviceId,
    required int passengerCount,
    double? distance,
    bool includePickup = false,
    DateTime? bookingDate,
  }) async {
    try {
      // Get service pricing
      final pricingList = await getServicePricing(serviceId);
      if (pricingList.isEmpty) return null;

      final pricing = pricingList.first;
      double basePrice = (pricing['base_price'] as num).toDouble();
      double totalPrice = basePrice;

      // Apply passenger multiplier for certain vehicle types
      if (passengerCount > 1) {
        totalPrice *= passengerCount;
      }

      // Add pickup fee if requested
      if (includePickup && pricing['pickup_fee'] != null) {
        totalPrice += (pricing['pickup_fee'] as num).toDouble();
      }

      // Apply distance-based pricing if available
      if (distance != null && pricing['pricing_type'] == 'per_km') {
        final perKmRate = (pricing['price_per_km'] as num?)?.toDouble() ?? 0;
        totalPrice += distance * perKmRate;
      }

      // Check for distance-based tiers
      if (distance != null) {
        final tiers = await getPricingTiers(serviceId);
        for (final tier in tiers) {
          final minDistance = (tier['min_distance_km'] as num).toDouble();
          final maxDistance = tier['max_distance_km'] != null
              ? (tier['max_distance_km'] as num).toDouble()
              : double.infinity;

          if (distance >= minDistance && distance < maxDistance) {
            totalPrice = (tier['price'] as num).toDouble() * passengerCount;
            break;
          }
        }
      }

      // Apply minimum fare if set
      if (pricing['minimum_fare'] != null) {
        final minFare = (pricing['minimum_fare'] as num).toDouble();
        if (totalPrice < minFare) {
          totalPrice = minFare;
        }
      }

      // Apply maximum fare if set
      if (pricing['maximum_fare'] != null) {
        final maxFare = (pricing['maximum_fare'] as num).toDouble();
        if (totalPrice > maxFare) {
          totalPrice = maxFare;
        }
      }

      // Apply weekend/holiday multipliers if booking date is provided
      if (bookingDate != null) {
        final isWeekend = bookingDate.weekday >= 6;
        if (isWeekend && pricing['weekend_multiplier'] != null) {
          final multiplier = (pricing['weekend_multiplier'] as num).toDouble();
          totalPrice *= multiplier;
        }
      }

      return {
        'base_price': basePrice,
        'total_price': totalPrice,
        'pickup_fee': includePickup ? (pricing['pickup_fee'] ?? 0) : 0,
        'passenger_count': passengerCount,
        'currency': pricing['currency'] ?? 'NAD',
        'pricing_breakdown': {
          'base': basePrice,
          'passengers': passengerCount,
          'pickup': includePickup ? (pricing['pickup_fee'] ?? 0) : 0,
          'distance_km': distance,
        }
      };
    } catch (e) {
      print('Error calculating transportation price: $e');
      return null;
    }
  }

  // Search services by criteria
  static Future<List<Map<String, dynamic>>> searchTransportationServices({
    String? originTownId,
    String? destinationTownId,
    String? subcategoryId,
    String? vehicleTypeId,
    DateTime? departureDate,
    int? minCapacity,
  }) async {
    var query = client.from('transportation_services').select('''
          *,
          subcategory:service_subcategories(name, service_categories(name)),
          provider:service_providers(name, rating, is_verified),
          vehicle_type:vehicle_types(name, capacity, features),
          route:routes(
            name, distance_km, estimated_duration_minutes,
            origin_town:towns!origin_town_id(name),
            destination_town:towns!destination_town_id(name)
          ),
          schedules:service_schedules(departure_time, arrival_time, days_of_week),
          pricing:service_pricing(base_price, pickup_fee, currency)
        ''').eq('is_active', true);

    if (subcategoryId != null) {
      query = query.eq('subcategory_id', subcategoryId);
    }

    if (vehicleTypeId != null) {
      query = query.eq('vehicle_type_id', vehicleTypeId);
    }

    final response = await query.order('name');
    List<Map<String, dynamic>> services =
        List<Map<String, dynamic>>.from(response);

    // Filter by route if origin/destination specified
    if (originTownId != null || destinationTownId != null) {
      services = services.where((service) {
        final route = service['route'];
        if (route == null) return false;

        bool matchOrigin = originTownId == null ||
            (route['origin_town'] != null &&
                route['origin_town']['id'] == originTownId);
        bool matchDestination = destinationTownId == null ||
            (route['destination_town'] != null &&
                route['destination_town']['id'] == destinationTownId);

        return matchOrigin && matchDestination;
      }).toList();
    }

    // Filter by vehicle capacity if specified
    if (minCapacity != null) {
      services = services.where((service) {
        final vehicleType = service['vehicle_type'];
        return vehicleType != null &&
            vehicleType['capacity'] != null &&
            vehicleType['capacity'] >= minCapacity;
      }).toList();
    }

    // Filter by departure date/day of week if specified
    if (departureDate != null) {
      final dayOfWeek = departureDate.weekday; // 1=Monday, 7=Sunday
      services = services.where((service) {
        final schedules = service['schedules'] as List?;
        if (schedules == null || schedules.isEmpty) return false;

        return schedules.any((schedule) {
          final daysOfWeek = schedule['days_of_week'] as List?;
          return daysOfWeek?.contains(dayOfWeek) == true;
        });
      }).toList();
    }

    return services;
  }

  // Service Reviews Management
  static Future<List<Map<String, dynamic>>> getServiceReviews(String serviceId,
      {bool verifiedOnly = true}) async {
    var query = client.from('service_reviews').select('''
          *,
          user:user_profiles(first_name, last_name, avatar_url)
        ''').eq('service_id', serviceId);

    if (verifiedOnly) {
      query = query.eq('is_verified', true);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServiceReview(
      Map<String, dynamic> reviewData) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      reviewData['user_id'] = user.id;

      final response = await client
          .from('service_reviews')
          .insert(reviewData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service review: $e');
      return null;
    }
  }

  // Admin Management Functions
  static Future<bool> updateServiceCategoryStatus(
      String categoryId, bool isActive) async {
    try {
      await client
          .from('service_categories')
          .update({'is_active': isActive}).eq('id', categoryId);
      return true;
    } catch (e) {
      print('Error updating category status: $e');
      return false;
    }
  }

  static Future<bool> updateTransportationServiceStatus(
      String serviceId, bool isActive) async {
    try {
      await client
          .from('transportation_services')
          .update({'is_active': isActive}).eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error updating service status: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllBookings(
      {String? status}) async {
    var query = client.from('transportation_bookings').select('''
          *,
          user:user_profiles(first_name, last_name, email, phone_number),
          service:transportation_services(
            name,
            provider:service_providers(name),
            vehicle_type:vehicle_types(name, capacity)
          )
        ''');

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
