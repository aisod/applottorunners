// Simple test to verify location picker functionality
import 'package:lotto_runners/services/location_service.dart';

void main() async {
  print('🧪 Testing Location Service...');

  // Test 1: Basic place search
  print('\n📍 Test 1: Basic place search');
  try {
    final results = await LocationService.searchPlaces('Windhoek');
    print('✅ Found ${results.length} results for "Windhoek"');
    for (var result in results) {
      print('   - ${result.mainText}: ${result.secondaryText}');
    }
  } catch (e) {
    print('❌ Error in basic search: $e');
  }

  // Test 2: Fallback search
  print('\n📍 Test 2: Fallback search');
  try {
    final results = await LocationService.searchPlaces('Swakopmund');
    print('✅ Found ${results.length} results for "Swakopmund"');
    for (var result in results) {
      print('   - ${result.mainText}: ${result.secondaryText}');
    }
  } catch (e) {
    print('❌ Error in fallback search: $e');
  }

  // Test 3: Address to coordinates
  print('\n📍 Test 3: Address to coordinates');
  try {
    final coords =
        await LocationService.getCoordinatesFromAddress('Windhoek, Namibia');
    if (coords != null) {
      print(
          '✅ Coordinates for Windhoek: ${coords['latitude']}, ${coords['longitude']}');
    } else {
      print('⚠️ No coordinates found for Windhoek');
    }
  } catch (e) {
    print('❌ Error getting coordinates: $e');
  }

  // Test 4: Coordinates to address
  print('\n📍 Test 4: Coordinates to address');
  try {
    final address =
        await LocationService.getAddressFromCoordinates(-22.5609, 17.0658);
    if (address != null) {
      print('✅ Address for Windhoek coordinates: $address');
    } else {
      print('⚠️ No address found for coordinates');
    }
  } catch (e) {
    print('❌ Error getting address: $e');
  }

  print('\n🏁 Location service test completed!');
}
