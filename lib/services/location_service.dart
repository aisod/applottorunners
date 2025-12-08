import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Prefer passing your key at build/run time: --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
  static const String _envApiKey =
      String.fromEnvironment('AIzaSyAkC1M3uRZhK_rGpAXCfIadUHuPXdWCkZo');

  // Fallback API keys for each platform (these should match your platform configs)
  static const String _androidApiKey =
      'AIzaSyAkC1M3uRZhK_rGpAXCfIadUHuPXdWCkZo';
  static const String _iosApiKey = 'AIzaSyAkC1M3uRZhK_rGpAXCfIadUHuPXdWCkZo';
  static const String _webApiKey = 'AIzaSyAkC1M3uRZhK_rGpAXCfIadUHuPXdWCkZo';
  static const String _macosApiKey = 'AIzaSyAkC1M3uRZhK_rGpAXCfIadUHuPXdWCkZo';

  // Cache for recent searches to improve performance
  static final Map<String, List<PlaceModel>> _searchCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Get the resolved API key, preferring environment variable, then platform-specific
  static String get _resolvedApiKey {
    if (_envApiKey.isNotEmpty &&
        _envApiKey != 'AIzaSyAkC1M3uRZhK_rGpAXCfIadUHuPXdWCkZo') {
      return _envApiKey;
    }

    // Return platform-specific key (this will work for the current platform)
    return _androidApiKey; // This will work for all platforms since they all use the same key
  }

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions';

  // Get current location
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission is required to use this feature. Please grant location permission in your device settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is permanently denied. Please enable it in your device settings to use this feature.');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Get address from coordinates
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // First try the geocoding package
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build a more readable address with null safety
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
    } catch (e) {
      print('Error getting address from coordinates with geocoding: $e');
      // Fall back to descriptive location name
      return _getDescriptiveLocationName(latitude, longitude);
    }

    // If geocoding fails, try Google's Geocoding API as fallback
    try {
      final apiKey = _resolvedApiKey;
      if (apiKey.isNotEmpty) {
        final url = Uri.parse(
          '$_baseUrl/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
        );

        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final result = data['results'][0];
            final formattedAddress = result['formatted_address'];
            if (formattedAddress != null && formattedAddress.isNotEmpty) {
              return formattedAddress;
            }
          }
        }
      }
    } catch (e) {
      print('Error getting address from coordinates with Google API: $e');
    }

    // If all geocoding fails, try to get a nearby landmark or create a descriptive name
    return _getDescriptiveLocationName(latitude, longitude);
  }

  // Get a descriptive location name when geocoding fails
  static String _getDescriptiveLocationName(double latitude, double longitude) {
    // Check if coordinates are in Namibia (approximate bounds)
    if (latitude >= -28.0 &&
        latitude <= -16.0 &&
        longitude >= 11.0 &&
        longitude <= 25.0) {
      // Check for major cities with more precise coordinates (0.05 degree tolerance ≈ 5.5km)
      if ((latitude - (-22.5609)).abs() < 0.05 &&
          (longitude - 17.0658).abs() < 0.05) {
        return 'Windhoek, Namibia';
      }
      if ((latitude - (-22.6749)).abs() < 0.05 &&
          (longitude - 14.5273).abs() < 0.05) {
        return 'Swakopmund, Namibia';
      }
      if ((latitude - (-26.6481)).abs() < 0.05 &&
          (longitude - 15.1538).abs() < 0.05) {
        return 'Lüderitz, Namibia';
      }
      if ((latitude - (-19.7667)).abs() < 0.05 &&
          (longitude - 17.7167).abs() < 0.05) {
        return 'Oshakati, Namibia';
      }
      if ((latitude - (-17.9333)).abs() < 0.05 &&
          (longitude - 19.7667).abs() < 0.05) {
        return 'Rundu, Namibia';
      }
      if ((latitude - (-24.6167)).abs() < 0.05 &&
          (longitude - 17.9667).abs() < 0.05) {
        return 'Rehoboth, Namibia';
      }

      // Return area description based on coordinates
      if (latitude > -20.0) {
        return 'Northern Namibia';
      } else if (latitude > -24.0) {
        return 'Central Namibia';
      } else {
        return 'Southern Namibia';
      }
    }

    // For other locations, return a formatted coordinate with context
    return 'Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
  }

  // Get coordinates from address
  static Future<Map<String, double>?> getCoordinatesFromAddress(
    String address,
  ) async {
    // Skip if address is empty or too short
    if (address.trim().isEmpty || address.trim().length < 3) {
      return null;
    }

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations[0];
        final lat = location.latitude;
        final lng = location.longitude;
        
        // Validate coordinates are valid numbers
        if (lat.isFinite && lng.isFinite) {
          return {
            'latitude': lat,
            'longitude': lng,
          };
        } else {
          print('❌ Invalid coordinates from address: $lat, $lng');
        }
      }
    } catch (e) {
      String errorMessage = 'Unknown error';
      try {
        errorMessage = e.toString();
      } catch (_) {
        errorMessage = 'Error occurred during geocoding';
      }
      print('Error getting coordinates from address: $errorMessage');
    }
    return null;
  }

  // Calculate distance between two coordinates using Haversine formula
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert degrees to radians
    final double lat1Rad = lat1 * pi / 180;
    final double lon1Rad = lon1 * pi / 180;
    final double lat2Rad = lat2 * pi / 180;
    final double lon2Rad = lon2 * pi / 180;

    // Haversine formula
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Get route distance using Google Maps Directions API (more accurate)
  static Future<RouteInfo?> getRouteDistance(
    double originLat,
    double originLon,
    double destinationLat,
    double destinationLon, {
    String? mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    final apiKey = _resolvedApiKey;
    if (apiKey.isEmpty) {
      // Fallback to direct distance calculation
      final distance = calculateDistanceKm(
          originLat, originLon, destinationLat, destinationLon);
      return RouteInfo(
        distanceKm: distance,
        durationMinutes:
            (distance * 2).round(), // Rough estimate: 2 minutes per km
        mode: mode ?? 'driving',
        isEstimated: true,
      );
    }

    try {
      final url = Uri.parse('$_directionsUrl/json?origin=$originLat,$originLon'
          '&destination=$destinationLat,$destinationLon'
          '&mode=$mode'
          '&key=$apiKey'
          '&units=metric');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final distance =
              leg['distance']['value'] / 1000; // Convert meters to km
          final duration =
              leg['duration']['value'] / 60; // Convert seconds to minutes

          return RouteInfo(
            distanceKm: distance.toDouble(),
            durationMinutes: duration.round(),
            mode: mode ?? 'driving',
            isEstimated: false,
          );
        }
      }
    } catch (e) {
      print('Error getting route distance: $e');
    }

    // Fallback to direct distance calculation
    final distance = calculateDistanceKm(
        originLat, originLon, destinationLat, destinationLon);
    return RouteInfo(
      distanceKm: distance,
      durationMinutes: (distance * 2).round(),
      mode: mode ?? 'driving',
      isEstimated: true,
    );
  }

  // Get distance between two addresses
  static Future<RouteInfo?> getAddressDistance(
    String originAddress,
    String destinationAddress, {
    String? mode = 'driving',
  }) async {
    try {
      // Get coordinates for both addresses
      final originCoords = await getCoordinatesFromAddress(originAddress);
      final destCoords = await getCoordinatesFromAddress(destinationAddress);

      if (originCoords != null && destCoords != null) {
        return await getRouteDistance(
          originCoords['latitude']!,
          originCoords['longitude']!,
          destCoords['latitude']!,
          destCoords['longitude']!,
          mode: mode,
        );
      }
    } catch (e) {
      print('Error calculating address distance: $e');
    }
    return null;
  }

  // Search for places using Google Places Autocomplete API with caching
  static Future<List<PlaceModel>> searchPlaces(String query) async {
    // Normalize query for caching
    final normalizedQuery = query.trim().toLowerCase();

    // Check cache first
    if (_searchCache.containsKey(normalizedQuery)) {
      final cacheTime = _cacheTimestamps[normalizedQuery];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        print('🚀 Using cached results for: $query');
        return _searchCache[normalizedQuery]!;
      } else {
        // Remove expired cache entry
        _searchCache.remove(normalizedQuery);
        _cacheTimestamps.remove(normalizedQuery);
      }
    }

    final apiKey = _resolvedApiKey;

    if (apiKey.isEmpty || apiKey == 'AIzaSyAkC1M3uRZhK_rGpAXCfIadUHuPXdWCkZo') {
      print(
          '⚠️ No valid API key found or using placeholder key, using fallback search');
      // Fallback to basic search without API key
      final results = await _basicPlaceSearch(query);
      _cacheResults(normalizedQuery, results);
      return results;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/place/autocomplete/json?input=$query&key=$apiKey&components=country:na&types=geocode', // Namibia country code, geocode only for faster results
      );

      print('🌐 Making optimized request to Google Places API');

      final response = await http.get(url).timeout(
        const Duration(seconds: 3), // Add timeout for faster failure
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          print('✅ Found ${predictions.length} places');
          final results = predictions
              .map((prediction) => PlaceModel.fromJson(prediction))
              .toList();

          // Cache successful results
          _cacheResults(normalizedQuery, results);
          return results;
        } else {
          print(
              '❌ API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          // Fallback to basic search on API error
          final results = await _basicPlaceSearch(query);
          _cacheResults(normalizedQuery, results);
          return results;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        final results = await _basicPlaceSearch(query);
        _cacheResults(normalizedQuery, results);
        return results;
      }
    } catch (e) {
      print('❌ Exception in searchPlaces: $e');
      // Fallback to basic search on exception
      final results = await _basicPlaceSearch(query);
      _cacheResults(normalizedQuery, results);
      return results;
    }
  }

  // Cache search results
  static void _cacheResults(String query, List<PlaceModel> results) {
    _searchCache[query] = results;
    _cacheTimestamps[query] = DateTime.now();

    // Clean up old cache entries to prevent memory leaks
    if (_searchCache.length > 50) {
      final now = DateTime.now();
      final keysToRemove = <String>[];

      for (final entry in _cacheTimestamps.entries) {
        if (now.difference(entry.value) > _cacheExpiry) {
          keysToRemove.add(entry.key);
        }
      }

      for (final key in keysToRemove) {
        _searchCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }

  // Clear cache (useful for testing or memory management)
  static void clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
    print('🧹 Location search cache cleared');
  }

  // Get place details
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final apiKey = _resolvedApiKey;
    if (apiKey.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/place/details/json?place_id=$placeId&key=$apiKey&fields=geometry,formatted_address',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceDetails.fromJson(data['result']);
      }
    } catch (e) {
      print('Error getting place details: $e');
    }

    return null;
  }

  // Basic place search without API key (fallback)
  static Future<List<PlaceModel>> _basicPlaceSearch(String query) async {
    print('🔍 Basic search for: $query');
    // Skip geocoding if query is too short or empty
    if (query.trim().isEmpty || query.trim().length < 2) {
      print('❌ Query too short for basic search');
      return [];
    }

    try {
      print('🌐 Attempting geocoding for: $query');
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations[0];
        // Ensure latitude and longitude are valid
        final lat = location.latitude;
        final lng = location.longitude;
        
        // Validate coordinates are valid numbers (not null, not NaN, not infinite)
        if (lat.isFinite && lng.isFinite) {
          print('✅ Found location: $lat, $lng');
          return [
            PlaceModel(
              placeId: 'basic_search',
              description: query,
              mainText: query,
              secondaryText: 'Searched location',
              latitude: lat,
              longitude: lng,
            ),
          ];
        } else {
          print('❌ Invalid coordinates: $lat, $lng');
        }
      } else {
        print('❌ No locations found for: $query');
      }
    } catch (e, stackTrace) {
      // Handle specific error types
      String errorMessage = 'Unknown error';
      try {
        errorMessage = e.toString();
      } catch (_) {
        // If toString() fails, use a safe fallback
        errorMessage = 'Error occurred during geocoding';
      }
      
      if (errorMessage.contains('null') || errorMessage.contains('Null')) {
        print('❌ Basic search error: Null value encountered - $errorMessage');
      } else {
        print('❌ Basic search error: $errorMessage');
      }
      // Continue to fallback locations below
    }

    // Return common locations in Namibia as fallback
    final queryLower = query.toLowerCase();
    List<PlaceModel> fallbackLocations = [];

    // Major cities in Namibia
    if (queryLower.contains('windhoek')) {
      fallbackLocations.add(PlaceModel(
        placeId: 'windhoek_city',
        description: 'Windhoek, Namibia',
        mainText: 'Windhoek',
        secondaryText: 'Khomas Region, Namibia',
        latitude: -22.5609,
        longitude: 17.0658,
      ));
    }

    if (queryLower.contains('swakopmund')) {
      fallbackLocations.add(PlaceModel(
        placeId: 'swakopmund_city',
        description: 'Swakopmund, Namibia',
        mainText: 'Swakopmund',
        secondaryText: 'Erongo Region, Namibia',
        latitude: -22.6749,
        longitude: 14.5273,
      ));
    }

    if (queryLower.contains('oshakati')) {
      fallbackLocations.add(PlaceModel(
        placeId: 'oshakati_city',
        description: 'Oshakati, Namibia',
        mainText: 'Oshakati',
        secondaryText: 'Oshana Region, Namibia',
        latitude: -19.7667,
        longitude: 17.7167,
      ));
    }

    if (queryLower.contains('rundu')) {
      fallbackLocations.add(PlaceModel(
        placeId: 'rundu_city',
        description: 'Rundu, Namibia',
        mainText: 'Rundu',
        secondaryText: 'Kavango East Region, Namibia',
        latitude: -17.9333,
        longitude: 19.7667,
      ));
    }

    if (queryLower.contains('walvis bay')) {
      fallbackLocations.add(PlaceModel(
        placeId: 'walvis_bay_city',
        description: 'Walvis Bay, Namibia',
        mainText: 'Walvis Bay',
        secondaryText: 'Erongo Region, Namibia',
        latitude: -22.9576,
        longitude: 14.5053,
      ));
    }

    // If no specific city matches, return common areas
    if (fallbackLocations.isEmpty) {
      if (queryLower.contains('north') || queryLower.contains('northern')) {
        fallbackLocations.add(PlaceModel(
          placeId: 'northern_namibia',
          description: 'Northern Namibia',
          mainText: 'Northern Namibia',
          secondaryText: 'Namibia',
          latitude: -18.0,
          longitude: 18.0,
        ));
      } else if (queryLower.contains('south') ||
          queryLower.contains('southern')) {
        fallbackLocations.add(PlaceModel(
          placeId: 'southern_namibia',
          description: 'Southern Namibia',
          mainText: 'Southern Namibia',
          secondaryText: 'Namibia',
          latitude: -25.0,
          longitude: 18.0,
        ));
      } else if (queryLower.contains('central')) {
        fallbackLocations.add(PlaceModel(
          placeId: 'central_namibia',
          description: 'Central Namibia',
          mainText: 'Central Namibia',
          secondaryText: 'Namibia',
          latitude: -22.0,
          longitude: 17.0,
        ));
      }
      // If no specific match found, return empty list to allow manual entry
      // Don't default to any location
    }

    return fallbackLocations;
  }
}

class RouteInfo {
  final double distanceKm;
  final int durationMinutes;
  final String mode;
  final bool isEstimated;

  RouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
    required this.mode,
    this.isEstimated = false,
  });

  @override
  String toString() {
    return 'RouteInfo(distance: ${distanceKm.toStringAsFixed(2)}km, duration: ${durationMinutes}min, mode: $mode, estimated: $isEstimated)';
  }
}

class PlaceModel {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;

  PlaceModel({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    
    if (location == null) {
      throw Exception('Location data is missing in place details');
    }
    
    final lat = location['lat'];
    final lng = location['lng'];
    
    if (lat == null || lng == null) {
      throw Exception('Latitude or longitude is null in place details');
    }
    
    return PlaceDetails(
      latitude: (lat is num) ? lat.toDouble() : double.parse(lat.toString()),
      longitude: (lng is num) ? lng.toDouble() : double.parse(lng.toString()),
      formattedAddress: json['formatted_address'] ?? '',
    );
  }
}
