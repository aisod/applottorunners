import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/app_log.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  StreamSubscription<Position>? _positionSubscription;
  String? _currentErrandId;
  String? _currentRunnerId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Starts live GPS tracking for an errand.
  Future<void> startTracking(String errandId, String runnerId) async {
    if (_isTracking) {
      if (_currentErrandId == errandId) return; // Already tracking this errand
      await stopTracking();
    }

    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      appLog('TrackingService: Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        appLog('TrackingService: Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      appLog('TrackingService: Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    _currentErrandId = errandId;
    _currentRunnerId = runnerId;
    _isTracking = true;

    // Use location settings that balance accuracy with battery
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15, // Only send update if they moved 15 meters
    );

    appLog('📡 TrackingService: Started tracking for errand $errandId');

    // Push initial location immediately if available
    try {
      Position initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateLocationInDatabase(initialPos);
    } catch (_) {}

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _updateLocationInDatabase(position);
    });
  }

  /// Stops tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    appLog('🛑 TrackingService: Stopped tracking for errand $_currentErrandId');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    
    // We do NOT delete the row, so the customer can see the last known location
    _currentErrandId = null;
    _currentRunnerId = null;
  }

  Future<void> _updateLocationInDatabase(Position position) async {
    if (_currentErrandId == null || _currentRunnerId == null) return;

    try {
      // Use upsert to create or replace the tracking row for this errand
      await SupabaseConfig.client.from('runner_tracking').upsert({
        'errand_id': _currentErrandId,
        'runner_id': _currentRunnerId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'updated_at': DateTime.now().toIso8601String(),
      });
      appLog('📍 TrackingService: Synced location -> ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
    } catch (e) {
      appLog('❌ TrackingService: Error updating database: $e');
    }
  }
}
