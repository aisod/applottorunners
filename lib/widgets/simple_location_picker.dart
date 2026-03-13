import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/location_service.dart';
import 'dart:async';
import 'map_picker_sheet.dart';

class SimpleLocationPicker extends StatefulWidget {
  final String? initialAddress;
  final String hintText;
  final String labelText;
  final IconData prefixIcon;
  final Color iconColor;
  final Function(String address, double? lat, double? lng) onLocationSelected;
  final String? Function(String?)? validator;

  const SimpleLocationPicker({
    super.key,
    this.initialAddress,
    required this.hintText,
    required this.labelText,
    required this.prefixIcon,
    required this.iconColor,
    required this.onLocationSelected,
    this.validator,
  });

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  List<PlaceModel> _searchResults = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _controller.text = widget.initialAddress!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showSuggestionOverlay();
    } else {
      // Delay hiding overlay to allow tap on suggestions
      Timer(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();

    if (value.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showSuggestions = false;
      });
      _updateOverlay();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchPlaces(value);
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);
    _updateOverlay(); // Update to show loading indicator

    try {
      final results = await LocationService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSuggestions = true;
        });
        _updateOverlay();
      }
    } catch (e) {
      print('Error searching places: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _showSuggestions = true;
        });
        _updateOverlay();
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
        _updateOverlay();
      }
    }
  }

  void _showSuggestionOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: _layerLink.leaderSize?.width ?? 300,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 60), // Push down below the text field
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              shadowColor: Colors.black.withOpacity(0.2),
              child: _buildSuggestionsList(),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.markNeedsBuild();
    } else if (_focusNode.hasFocus) {
      _showSuggestionOverlay();
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
  }

  Widget _buildSuggestionsList() {
    // Get screen size for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final textSize = isMobile
        ? 14.0
        : isTablet
            ? 15.0
            : 16.0;
    final subtitleSize = isMobile
        ? 12.0
        : isTablet
            ? 13.0
            : 14.0;
    final iconSize = isMobile ? 20.0 : 24.0;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Searching...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: textSize,
                        ),
                      ),
                    ],
                  ),
                ),

              // Static Options
              _buildOptionTile(
                icon: Icons.my_location,
                title: 'Use current location',
                subtitle: 'Get your current GPS location',
                onTap: _useCurrentLocation,
                iconColor: widget.iconColor,
              ),
              _buildOptionTile(
                icon: Icons.map,
                title: 'Pick on map',
                subtitle: 'Select exact location on map',
                onTap: _openMapPicker,
                iconColor: widget.iconColor,
              ),

              if (_searchResults.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'SUGGESTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                ..._searchResults
                    .take(5)
                    .map((place) => _buildPlaceTile(place)),
              ] else if (_controller.text.isNotEmpty && !_isSearching) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'No matching locations found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: textSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          _removeOverlay();
                          _focusNode.unfocus();
                          widget.onLocationSelected(
                              _controller.text, null, null);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Use entered address anyway'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildPlaceTile(PlaceModel place) {
    return InkWell(
      onTap: () => _selectPlace(place),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.mainText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.secondaryText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    _removeOverlay();
    _focusNode.unfocus();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Getting your location...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (address != null) {
          setState(() {
            _controller.text = address;
          });

          widget.onLocationSelected(
            address,
            position.latitude,
            position.longitude,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location found successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('Unable to get address for your location.');
        }
      } else {
        throw Exception('Unable to get your current location.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Failed to get current location. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _selectPlace(PlaceModel place) async {
    _removeOverlay();
    _focusNode.unfocus();

    if (!mounted) return;

    final selectedAddress = place.description;
    setState(() {
      _controller.text = selectedAddress;
    });

    double? lat = place.latitude;
    double? lng = place.longitude;

    // If coordinates are not available, try to get them
    if (lat == null || lng == null) {
      // First try to get details using place_id if available
      if (place.placeId.isNotEmpty) {
        try {
          final details = await LocationService.getPlaceDetails(place.placeId);
          if (details != null) {
            lat = details.latitude;
            lng = details.longitude;
          }
        } catch (e) {
          print('Error getting place details: $e');
        }
      }

      // If still no coordinates, try geocoding from address string
      if (lat == null || lng == null) {
        final coords = await LocationService.getCoordinatesFromAddress(
          selectedAddress,
        );
        if (coords != null) {
          lat = coords['latitude'];
          lng = coords['longitude'];
        }
      }
    }

    if (mounted) {
      widget.onLocationSelected(selectedAddress, lat, lng);
    }
  }

  Future<void> _openMapPicker() async {
    _removeOverlay();
    _focusNode.unfocus();

    if (!mounted) return;

    try {
      final result = await Navigator.of(context).push<PickedLocation>(
        MaterialPageRoute(
          fullscreenDialog: false,
          builder: (context) => MapPickerSheet(accentColor: widget.iconColor),
        ),
      );

      if (result != null && mounted) {
        final selectedAddress = result.address;
        setState(() {
          _controller.text = selectedAddress;
        });
        widget.onLocationSelected(
          selectedAddress,
          result.latitude,
          result.longitude,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to open map picker.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    final textSize = isMobile
        ? 14.0
        : isTablet
            ? 15.0
            : 16.0;
    final labelSize = isMobile
        ? 14.0
        : isTablet
            ? 15.0
            : 16.0;
    final hintSize = isMobile
        ? 13.0
        : isTablet
            ? 14.0
            : 15.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final padding = isMobile ? 12.0 : 16.0;
    final borderRadius = isMobile ? 10.0 : 12.0;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        style: TextStyle(fontSize: textSize),
        keyboardType: TextInputType.streetAddress,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(fontSize: labelSize),
          hintText: widget.hintText,
          hintStyle: TextStyle(fontSize: hintSize),
          helperText:
              'You can search or manually enter: Region, Street Name, House #',
          helperStyle: TextStyle(fontSize: isMobile ? 11.0 : 12.0),
          helperMaxLines: 2,
          prefixIcon:
              Icon(widget.prefixIcon, color: widget.iconColor, size: iconSize),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onLocationSelected('', null, null);
                    setState(() {
                      _searchResults.clear();
                    });
                    _removeOverlay();
                  },
                  icon: Icon(Icons.clear,
                      color: widget.iconColor, size: iconSize),
                  tooltip: 'Clear',
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: padding,
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: widget.iconColor, width: 2),
          ),
        ),
        onChanged: (value) {
          _onTextChanged(value);
          if (value.isNotEmpty && value.length > 5) {
            widget.onLocationSelected(value, null, null);
          }
        },
        onFieldSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.onLocationSelected(value, null, null);
            _focusNode.unfocus();
          }
        },
        validator: widget.validator,
      ),
    );
  }
}
