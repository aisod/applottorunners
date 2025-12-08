import 'package:supabase_flutter/supabase_flutter.dart';

// Test function to add a provider to an existing transportation service
Future<void> testAddProviderToService() async {
  try {
    // Initialize Supabase (you'll need to add your credentials)
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );

    final client = Supabase.instance.client;

    // First, let's check what providers exist
    final providersResponse =
        await client.from('service_providers').select('id, name').order('name');

    print('Available providers:');
    for (var provider in providersResponse) {
      print('- ${provider['name']} (ID: ${provider['id']})');
    }

    // Check what services exist
    final servicesResponse = await client
        .from('transportation_services')
        .select('id, name, provider_ids')
        .order('name');

    print('\nAvailable services:');
    for (var service in servicesResponse) {
      print(
          '- ${service['name']} (ID: ${service['id']}) - Provider count: ${(service['provider_ids'] as List?)?.length ?? 0}');
    }

    // If we have both providers and services, add a provider to the first service
    if (providersResponse.isNotEmpty && servicesResponse.isNotEmpty) {
      final firstProvider = providersResponse[0];
      final firstService = servicesResponse[0];

      print(
          '\nAdding provider "${firstProvider['name']}" to service "${firstService['name']}"');

      // Add provider to service using the existing function
      final success = await addProviderToService(
        firstService['id'],
        {
          'provider_id': firstProvider['id'],
          'price': 150.0,
          'departure_time': '08:00',
          'check_in_time': '07:30',
          'days_of_week': [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday'
          ],
          'advance_booking_hours': 1,
          'cancellation_hours': 2,
        },
      );

      if (success) {
        print('✅ Successfully added provider to service');
      } else {
        print('❌ Failed to add provider to service');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}

// Helper function to add provider to service (copied from SupabaseConfig)
Future<bool> addProviderToService(
    String serviceId, Map<String, dynamic> providerData) async {
  try {
    final client = Supabase.instance.client;

    // Handle days_of_week - ensure it's always a valid array of integers
    List<int> operatingDays = [];
    if (providerData['days_of_week'] != null) {
      if (providerData['days_of_week'] is List) {
        List<String> dayNames = List<String>.from(providerData['days_of_week']);
        operatingDays =
            dayNames.map((dayName) => _convertDayNameToInt(dayName)).toList();
      } else if (providerData['days_of_week'] is String) {
        operatingDays = [_convertDayNameToInt(providerData['days_of_week'])];
      }
    }

    if (operatingDays.isEmpty) {
      operatingDays = [1]; // Default to Monday
    }

    await client.rpc('add_provider_to_service', params: {
      'p_service_id': serviceId,
      'p_provider_id': providerData['provider_id'],
      'p_price': providerData['price'],
      'p_departure_time': providerData['departure_time'],
      'p_check_in_time': providerData['check_in_time'],
      'p_operating_days': operatingDays,
      'p_advance_booking_hours': providerData['advance_booking_hours'] ?? 1,
      'p_cancellation_hours': providerData['cancellation_hours'] ?? 2,
    });
    return true;
  } catch (e) {
    print('Error adding provider to service: $e');
    return false;
  }
}

// Helper function to convert day names to integers
int _convertDayNameToInt(String dayName) {
  switch (dayName.toLowerCase()) {
    case 'monday':
      return 1;
    case 'tuesday':
      return 2;
    case 'wednesday':
      return 3;
    case 'thursday':
      return 4;
    case 'friday':
      return 5;
    case 'saturday':
      return 6;
    case 'sunday':
      return 7;
    default:
      return 1;
  }
}
