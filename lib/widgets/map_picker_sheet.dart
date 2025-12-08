import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lotto_runners/services/location_service.dart';

class PickedLocation {
  final String address;
  final double latitude;
  final double longitude;

  PickedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class MapPickerSheet extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Color accentColor;

  const MapPickerSheet({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.accentColor,
  });

  @override
  State<MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<MapPickerSheet> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _selectedPosition = const LatLng(-22.5609, 17.0658); // Windhoek default
  bool _isLoading = true;
  String? _currentAddress;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  Future<void> _initializePosition() async {
    try {
      LatLng start = _selectedPosition;

      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        start = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      } else {
        final pos = await LocationService.getCurrentPosition().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
        if (pos != null) {
          start = LatLng(pos.latitude, pos.longitude);
        }
      }

      if (mounted) {
        setState(() {
          _selectedPosition = start;
          _isLoading = false;
        });
        // Get initial address after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _updateAddress();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAddress() async {
    if (!mounted) return;
    try {
      final addr = await LocationService.getAddressFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );
      if (mounted) {
        setState(() => _currentAddress = addr);
      }
    } catch (e) {
      // Ignore geocoding errors
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final controller = await _mapController.future;
      final pos = await LocationService.getCurrentPosition();
      if (pos != null && mounted) {
        final target = LatLng(pos.latitude, pos.longitude);
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 16),
          ),
        );
        if (mounted) {
          setState(() => _selectedPosition = target);
          _updateAddress();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to get current location'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _confirmSelection() {
    if (!mounted) return;
    
    final address = _currentAddress ??
        '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}';
    
    Navigator.of(context).pop(
      PickedLocation(
        address: address,
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Location'),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 1,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GestureDetector(
                // Intercept gestures to prevent external app opening
                onTap: () {},
                onPanUpdate: (_) {},
                child: Stack(
                  children: [
                    AbsorbPointer(
                      // Temporarily absorb pointer events during map initialization
                      absorbing: !_mapReady,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedPosition,
                          zoom: 15,
                        ),
                        myLocationEnabled: false, // Disable to prevent external app opening
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapType: MapType.normal,
                        mapToolbarEnabled: false, // Critical: disable toolbar to prevent external links
                        compassEnabled: false, // Disable compass
                        rotateGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        tiltGesturesEnabled: false,
                        zoomGesturesEnabled: true,
                        onMapCreated: (controller) {
                          if (!_mapController.isCompleted) {
                            _mapController.complete(controller);
                          }
                          if (mounted) {
                            setState(() => _mapReady = true);
                          }
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedPosition,
                            infoWindow: const InfoWindow(
                              title: 'Selected Location',
                            ),
                          ),
                        },
                        onTap: (pos) {
                          if (mounted) {
                            setState(() {
                              _selectedPosition = pos;
                            });
                            _updateAddress();
                            // Update marker position
                            _mapController.future.then((controller) {
                              controller.animateCamera(
                                CameraUpdate.newLatLng(pos),
                              );
                            });
                          }
                        },
                        onCameraMove: (position) {
                          if (mounted) {
                            setState(() {
                              _selectedPosition = position.target;
                            });
                          }
                        },
                        onCameraIdle: () {
                          _updateAddress();
                        },
                      ),
                    ),
                  // Center indicator
                  const Center(
                    child: Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  // Bottom controls
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentAddress != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _currentAddress!,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (_currentAddress != null) const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _goToCurrentLocation,
                                icon: Icon(Icons.my_location, color: widget.accentColor),
                                label: Text(
                                  'My Location',
                                  style: TextStyle(color: widget.accentColor),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: widget.accentColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _confirmSelection,
                                icon: const Icon(Icons.check),
                                label: const Text('Confirm'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.accentColor,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
