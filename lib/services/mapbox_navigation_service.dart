import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:lotto_runners/utils/app_log.dart';

class MapboxNavigationService {
  static final MapboxNavigationService _instance = MapboxNavigationService._internal();
  factory MapboxNavigationService() => _instance;
  MapboxNavigationService._internal();

  /// True only on Android or iOS — the only platforms Mapbox navigation supports.
  static bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  MapBoxNavigation? _directions;
  MapBoxOptions? _options;
  final bool _isMultipleStop = false;
  double? _distanceRemaining, _durationRemaining;
  final String _instruction = '';
  final bool _routeBuilt = false;
  final bool _isNavigating = false;

  Future<void> initialize() async {
    if (!_isMobile) return;
    _options = MapBoxOptions(
      initialLatitude: -22.55941, // Windhoek default
      initialLongitude: 17.08323,
      zoom: 15.0,
      tilt: 0.0,
      bearing: 0.0,
      enableRefresh: false,
      alternatives: true,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      allowsUTurnAtWayPoints: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: false,
      language: 'en',
    );
  }

  /// Starts navigation with a list of map points (name, lat, lng).
  /// Safe to call on Web (will be a no-op).
  Future<void> startNavigationWithPoints(List<dynamic> points) async {
    if (!_isMobile) {
      appLog('Navigation only supported on Android/iOS, not on this platform.');
      return;
    }

    final List<WayPoint> wayPoints = [];
    for (var p in points) {
      if (p is Map) {
        wayPoints.add(WayPoint(
          name: p['name'] ?? 'Point',
          latitude: p['lat'],
          longitude: p['lng'],
        ));
      }
    }

    if (wayPoints.isEmpty) return;

    await MapBoxNavigation.instance.startNavigation(
      wayPoints: wayPoints,
      options: _options ?? MapBoxOptions(
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: false,
        language: 'en',
      ),
    );
  }

  Future<void> startNavigation({
    required List<WayPoint> wayPoints,
    MapBoxOptions? options,
  }) async {
    if (!_isMobile) {
      throw Exception('Navigation is only supported on Android/iOS. Please use a mobile device.');
    }

    if (wayPoints.isEmpty) {
      throw Exception('At least one waypoint is required.');
    }

    await MapBoxNavigation.instance.startNavigation(
      wayPoints: wayPoints,
      options: options ?? _options ?? MapBoxOptions(
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: false,
        language: 'en',
      ),
    );
  }
}
