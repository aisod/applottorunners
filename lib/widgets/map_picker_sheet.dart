import 'dart:async';

import 'package:flutter/material.dart';
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
  bool _isMoving = false;

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
      setState(() => _isMoving = false);
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
        // _selectedPosition will be updated by onCameraMove/onCameraIdle
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
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedPosition,
                      zoom: 15,
                    ),
                    // Disable GoogleMap's built-in myLocation layer to avoid
                    // native crashes when runtime permissions are missing.
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
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
                    // Removed markers to avoid duplication with the center pin
                    markers: {},
                    onCameraMove: (position) {
                      if (mounted) {
                        setState(() {
                          _selectedPosition = position.target;
                          _isMoving = true;
                        });
                      }
                    },
                    onCameraIdle: () {
                      _updateAddress();
                    },
                  ),
                  
                  // Center Pin
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 35.0), // Adjust for pin height
                      child: Icon(
                        Icons.location_on,
                        color: widget.accentColor,
                        size: 50,
                      ),
                    ),
                  ),
                  
                  // Center Pin Shadow/Dot
                  Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Bottom Card
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton(
                          onPressed: _goToCurrentLocation,
                          backgroundColor: theme.colorScheme.surface,
                          foregroundColor: widget.accentColor,
                          mini: true,
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Selected Location',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: widget.accentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _isMoving
                                        ? Text(
                                            'Locating...',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          )
                                        : Text(
                                            _currentAddress ?? 'Unknown location',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _isMoving ? null : _confirmSelection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.accentColor,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Confirm Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
