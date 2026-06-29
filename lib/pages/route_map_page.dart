import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/services/location_service.dart';
import 'package:lotto_runners/utils/map_utils.dart';
import 'package:lotto_runners/services/mapbox_navigation_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lotto_runners/utils/app_log.dart';
// Conditional import for Mapbox Navigation on mobile platforms only
// import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart' if (dart.library.html) 'package:lotto_runners/services/mapbox_stub.dart';

/// In-app map showing the route to the errand location (Yango-style).
/// Shows pickup marker, dropoff marker, user location, and route polyline.
class RouteMapPage extends StatefulWidget {
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? title;

  const RouteMapPage({
    super.key,
    this.pickupAddress,
    this.dropoffAddress,
    this.title,
  });

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _pickup;
  LatLng? _dropoff;
  LatLng? _myLocation;
  List<LatLng> _polylinePoints = [];
  bool _loading = true;
  String? _error;
  static const LatLng _defaultCenter = LatLng(-22.5609, 17.0658); // Windhoek

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final pickup = widget.pickupAddress?.trim() ?? '';
    final dropoff = widget.dropoffAddress?.trim() ?? '';

    if (pickup.isEmpty && dropoff.isEmpty) {
      setState(() {
        _error = 'No addresses provided';
        _loading = false;
      });
      return;
    }

    try {
      // Get current position
      Position? pos = await LocationService.getCurrentPosition();
      LatLng? my;
      if (pos != null) {
        my = LatLng(pos.latitude, pos.longitude);
      }

      // Geocode locations
      LatLng? pCoords;
      if (pickup.isNotEmpty) {
        final pc = await LocationService.getCoordinatesFromAddress(pickup);
        if (pc != null) pCoords = LatLng(pc['latitude']!, pc['longitude']!);
      }

      LatLng? dCoords;
      if (dropoff.isNotEmpty) {
        final dc = await LocationService.getCoordinatesFromAddress(dropoff);
        if (dc != null) dCoords = LatLng(dc['latitude']!, dc['longitude']!);
      }

      if (pCoords == null && dCoords == null) {
        setState(() {
          _error = 'Could not find locations for the provided addresses';
          _loading = false;
        });
        return;
      }

      // Fetch route segments
      List<LatLng> fullPolyline = [];
      
      // 1. My Location -> Pickup (if exists)
      if (my != null && pCoords != null) {
        final encoded1 = await LocationService.getRoutePolylineEncoded(
          my.latitude, my.longitude, pCoords.latitude, pCoords.longitude);
        if (encoded1 != null) {
          fullPolyline.addAll(MapUtils.decodePolyline(encoded1).map((p) => LatLng(p.lat, p.lng)));
        }
      }

      // 2. Pickup -> Dropoff (or My -> Dropoff if no pickup)
      final startPoint = pCoords ?? my;
      if (startPoint != null && dCoords != null) {
        final encoded2 = await LocationService.getRoutePolylineEncoded(
          startPoint.latitude, startPoint.longitude, dCoords.latitude, dCoords.longitude);
        if (encoded2 != null) {
          fullPolyline.addAll(MapUtils.decodePolyline(encoded2).map((p) => LatLng(p.lat, p.lng)));
        }
      }

      if (mounted) {
        setState(() {
          _pickup = pCoords;
          _dropoff = dCoords;
          _myLocation = my;
          _polylinePoints = fullPolyline;
          _loading = false;
          _error = null;
        });
        // Wait for map to be ready before fitting bounds
        if (_mapController.isCompleted) {
          _fitBounds();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load route: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fitBounds() async {
    final controller = await _mapController.future;
    List<LatLng> points = [];
    if (_myLocation != null) points.add(_myLocation!);
    if (_pickup != null) points.add(_pickup!);
    if (_dropoff != null) points.add(_dropoff!);

    if (points.isEmpty) return;

    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
    } else {
      final bounds = _boundsFromPoints(points);
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
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
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _startNavigation() async {
    if (kIsWeb) {
      // On Web, open Google Maps Navigation in a new tab
      final dCoords = _dropoff;
      if (dCoords != null) {
        final url = 'https://www.google.com/maps/dir/?api=1&destination=${dCoords.latitude},${dCoords.longitude}&travelmode=driving';
        await MapUtils.openExternalMap(dCoords.latitude, dCoords.longitude);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No destination to navigate to')));
      }
      return;
    }

    // Mobile logic
    try {
      final List<dynamic> wayPoints = [];
      
      if (_myLocation != null) {
        wayPoints.add({'name': 'My Location', 'lat': _myLocation!.latitude, 'lng': _myLocation!.longitude});
      }
      if (_pickup != null) {
        wayPoints.add({'name': 'Pickup', 'lat': _pickup!.latitude, 'lng': _pickup!.longitude});
      }
      if (_dropoff != null) {
        wayPoints.add({'name': 'Dropoff', 'lat': _dropoff!.latitude, 'lng': _dropoff!.longitude});
      }

      // If My Location is missing but we have Pickup AND Dropoff, we can still navigate between them
      if (wayPoints.length < 2) {
        String missing = '';
        if (_myLocation == null) missing += 'current location, ';
        if (_pickup == null && widget.pickupAddress != null) missing += 'pickup address, ';
        if (_dropoff == null && widget.dropoffAddress != null) missing += 'dropoff address, ';
        
        if (missing.isNotEmpty) {
          missing = missing.substring(0, missing.length - 2);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot start navigation. Waiting for: $missing. Please ensure GPS is on and addresses are correct.'))
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough points to start navigation.'))
          );
        }
        return;
      }

      await MapboxNavigationService().startNavigationWithPoints(wayPoints);
    } catch (e) {
      appLog('❌ Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigation error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = _pickup ?? _dropoff ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Route Map',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: _loadRoute, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: center, zoom: 14),
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
                            infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickupAddress),
                          ),
                        if (_dropoff != null)
                          Marker(
                            markerId: const MarkerId('dropoff'),
                            position: _dropoff!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                            infoWindow: InfoWindow(title: 'Dropoff', snippet: widget.dropoffAddress),
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
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLocationCard(theme),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _startNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LottoRunnersColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              minimumSize: const Size(double.infinity, 56),
                              elevation: 4,
                            ),
                            child: const Text('Start Navigation', 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          if (widget.pickupAddress != null)
            _buildLocationRow(Icons.location_on, Colors.yellow, 'Pickup', widget.pickupAddress!),
          if (widget.pickupAddress != null && widget.dropoffAddress != null)
            const Divider(height: 24),
          if (widget.dropoffAddress != null)
            _buildLocationRow(Icons.flag, Colors.orange, 'Dropoff', widget.dropoffAddress!),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String label, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(address, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
