import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/services/location_service.dart';
import 'package:lotto_runners/utils/map_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lotto_runners/utils/app_log.dart';

class CustomerTrackingPage extends StatefulWidget {
  final Map<String, dynamic> errand;

  const CustomerTrackingPage({
    super.key,
    required this.errand,
  });

  @override
  State<CustomerTrackingPage> createState() => _CustomerTrackingPageState();
}

class _CustomerTrackingPageState extends State<CustomerTrackingPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  RealtimeChannel? _trackingChannel;

  LatLng? _pickup;
  LatLng? _dropoff;
  LatLng? _runnerLocation;
  double _runnerHeading = 0.0;
  List<LatLng> _polylinePoints = [];

  bool _loading = true;
  String? _error;

  static const LatLng _defaultCenter = LatLng(-22.5609, 17.0658);

  @override
  void initState() {
    super.initState();
    _loadInitialLocations();
    _subscribeToLiveTracking();
  }

  @override
  void dispose() {
    _trackingChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadInitialLocations() async {
    try {
      final errand = widget.errand;
      String pickupAddress = errand['pickup_address'] ?? errand['location_address'] ?? '';
      String dropoffAddress = errand['delivery_address'] ?? errand['dropoff_address'] ?? '';

      // Geocode locations
      LatLng? pCoords;
      if (pickupAddress.isNotEmpty) {
        final pc = await LocationService.getCoordinatesFromAddress(pickupAddress);
        if (pc != null) pCoords = LatLng(pc['latitude']!, pc['longitude']!);
      }

      LatLng? dCoords;
      if (dropoffAddress.isNotEmpty) {
        final dc = await LocationService.getCoordinatesFromAddress(dropoffAddress);
        if (dc != null) dCoords = LatLng(dc['latitude']!, dc['longitude']!);
      }

      // Check if runner already has a location in DB
      final response = await SupabaseConfig.client
          .from('runner_tracking')
          .select()
          .eq('errand_id', errand['id'])
          .maybeSingle();

      if (response != null) {
        _runnerLocation = LatLng(response['latitude'] as double, response['longitude'] as double);
        _runnerHeading = (response['heading'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _pickup = pCoords;
          _dropoff = dCoords;
          _loading = false;
        });

        _fitBounds();
        _updateRoutePolyline();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error loading locations: $e';
        });
      }
    }
  }

  void _subscribeToLiveTracking() {
    final errandId = widget.errand['id'];
    _trackingChannel = SupabaseConfig.client
        .channel('public:runner_tracking:errand_id=eq.$errandId')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'runner_tracking',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'errand_id',
              value: errandId,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (mounted) {
                setState(() {
                  _runnerLocation = LatLng(
                      newRecord['latitude'] as double, newRecord['longitude'] as double);
                  _runnerHeading = (newRecord['heading'] as num?)?.toDouble() ?? 0.0;
                });
                _animateMarkerTo(_runnerLocation!);
                _updateRoutePolyline();
              }
                        })
        .subscribe();
  }

  Future<void> _updateRoutePolyline() async {
    // Only update polyline from runner to dropoff if both exist
    if (_runnerLocation != null && (_dropoff != null || _pickup != null)) {
      final target = _dropoff ?? _pickup!;
      try {
        final encoded = await LocationService.getRoutePolylineEncoded(
          _runnerLocation!.latitude,
          _runnerLocation!.longitude,
          target.latitude,
          target.longitude,
        );
        if (encoded != null && mounted) {
          setState(() {
            _polylinePoints = MapUtils.decodePolyline(encoded).map((p) => LatLng(p.lat, p.lng)).toList();
          });
        }
      } catch (e) {
        appLog('Error fetching polyline: $e');
      }
    }
  }

  Future<void> _animateMarkerTo(LatLng location) async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(location));
    }
  }

  Future<void> _fitBounds() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    
    List<LatLng> points = [];
    if (_pickup != null) points.add(_pickup!);
    if (_dropoff != null) points.add(_dropoff!);
    if (_runnerLocation != null) points.add(_runnerLocation!);

    if (points.isEmpty) return;

    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
    } else {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      final bounds = LatLngBounds(
        southwest: LatLng(minLat - 0.005, minLng - 0.005),
        northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
      );
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runnerName = widget.errand['runner'] != null 
        ? (widget.errand['runner'] is List && widget.errand['runner'].isNotEmpty 
            ? widget.errand['runner'][0]['full_name'] 
            : widget.errand['runner']['full_name']) 
        : 'Runner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(target: _defaultCenter, zoom: 14),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        _mapController.complete(controller);
                        _fitBounds();
                      },
                      markers: {
                        if (_pickup != null)
                          Marker(
                            markerId: const MarkerId('pickup'),
                            position: _pickup!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                            infoWindow: const InfoWindow(title: 'Pickup'),
                          ),
                        if (_dropoff != null)
                          Marker(
                            markerId: const MarkerId('dropoff'),
                            position: _dropoff!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                            infoWindow: const InfoWindow(title: 'Dropoff'),
                          ),
                        if (_runnerLocation != null)
                          Marker(
                            markerId: const MarkerId('runner'),
                            position: _runnerLocation!,
                            rotation: _runnerHeading,
                            flat: true,
                            anchor: const Offset(0.5, 0.5),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            infoWindow: InfoWindow(title: runnerName),
                          ),
                      },
                      polylines: {
                        if (_polylinePoints.isNotEmpty)
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: _polylinePoints,
                            color: LottoRunnersColors.primaryBlue,
                            width: 5,
                          ),
                      },
                    ),
                    
                    // Top Info Panel
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4)
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.delivery_dining, color: LottoRunnersColors.primaryBlue, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _runnerLocation != null 
                                      ? '$runnerName is on the way' 
                                      : 'Waiting for runner location...',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (_runnerLocation != null)
                                    Text('Tracking active', style: TextStyle(color: Colors.green.shade600, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (_runnerLocation != null)
                              const Icon(Icons.satellite_alt, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
