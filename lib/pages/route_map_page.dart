import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/services/location_service.dart';
import 'package:lotto_runners/utils/map_utils.dart';

/// In-app map showing the route to the errand location (Yango-style).
/// Shows destination marker, user location, and route polyline when available.
class RouteMapPage extends StatefulWidget {
  final String destinationAddress;
  final String? title;

  const RouteMapPage({
    super.key,
    required this.destinationAddress,
    this.title,
  });

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _destination;
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
    final address = widget.destinationAddress.trim();
    if (address.isEmpty) {
      setState(() {
        _error = 'No address provided';
        _loading = false;
      });
      return;
    }

    try {
      // Geocode destination
      final coords = await LocationService.getCoordinatesFromAddress(address);
      if (coords == null) {
        setState(() {
          _error = 'Could not find location for this address';
          _loading = false;
        });
        return;
      }
      final dest = LatLng(coords['latitude']!, coords['longitude']!);

      // Get current position
      Position? pos = await LocationService.getCurrentPosition();
      LatLng? my;
      if (pos != null) {
        my = LatLng(pos.latitude, pos.longitude);
      }

      // Optional: fetch route polyline (when API key is set)
      List<LatLng> polyline = [];
      if (my != null) {
        final encoded = await LocationService.getRoutePolylineEncoded(
          my.latitude,
          my.longitude,
          dest.latitude,
          dest.longitude,
        );
        if (encoded != null && encoded.isNotEmpty) {
          final decoded = MapUtils.decodePolyline(encoded);
          polyline = decoded
              .map((p) => LatLng(p.lat, p.lng))
              .toList();
        }
      }

      if (mounted) {
        setState(() {
          _destination = dest;
          _myLocation = my;
          _polylinePoints = polyline;
          _loading = false;
          _error = null;
        });
        // Bounds will be applied when map is created (onMapCreated)
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load route';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fitBounds() async {
    final dest = _destination;
    final my = _myLocation;
    if (dest == null) return;

    final controller = await _mapController.future;
    if (my != null) {
      final bounds = _boundsFromPoints([dest, my]);
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } else {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(dest, 15),
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = _destination ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Route to location',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
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
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _loadRoute();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: center,
                        zoom: 14,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      mapType: MapType.normal,
                      compassEnabled: true,
                      onMapCreated: (controller) {
                        if (!_mapController.isCompleted) {
                          _mapController.complete(controller);
                        }
                        // Fit camera to show destination and user location once map is ready
                        Future.microtask(() => _fitBounds());
                      },
                      markers: {
                        if (_destination != null)
                          Marker(
                            markerId: const MarkerId('destination'),
                            position: _destination!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange,
                            ),
                            infoWindow: InfoWindow(
                              title: 'Destination',
                              snippet: widget.destinationAddress,
                            ),
                          ),
                      },
                      polylines: _polylinePoints.isEmpty
                          ? {}
                          : {
                              Polyline(
                                polylineId: const PolylineId('route'),
                                points: _polylinePoints,
                                color: LottoRunnersColors.primaryBlue,
                                width: 5,
                              ),
                            },
                    ),
                    // Destination card at bottom
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: LottoRunnersColors.primaryYellow,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Destination',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.destinationAddress,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
