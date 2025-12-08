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
      if (kIsWeb) {
        // For web, just update the state to show inline suggestions
        setState(() {
          _showSuggestions = _searchResults.isNotEmpty;
        });
      } else {
        _showSuggestionOverlay();
      }
    } else {
      // Delay hiding overlay to allow tap on suggestions
      Timer(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          if (kIsWeb) {
            setState(() {
              _showSuggestions = false;
            });
          } else {
            _removeOverlay();
          }
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

    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _searchPlaces(value);
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);

    try {
      final results = await LocationService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _showSuggestions = _focusNode.hasFocus && results.isNotEmpty;
      });

      if (kIsWeb) {
        // For web, the suggestions are shown inline, no overlay needed
      } else {
        _updateOverlay();
      }
    } catch (e) {
      print('Error searching places: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to search locations. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        _searchResults = [];
        _showSuggestions = _focusNode.hasFocus;
      });

      if (kIsWeb) {
        // For web, the suggestions are shown inline, no overlay needed
      } else {
        _updateOverlay();
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showSuggestionOverlay() {
    _removeOverlay();

    // For web, use a simpler overlay approach
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateOverlay();
      });
      return;
    }

    // Add safety check for renderbox (mobile)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.attached) return;

      final RenderBox renderBox = renderObject as RenderBox;
      if (!renderBox.hasSize) return;

      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 4,
          width: size.width,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: _buildSuggestionsList(),
          ),
        ),
      );

      final overlay = Overlay.of(context);
      if (overlay.mounted) {
        overlay.insert(_overlayEntry!);
      }
    });
  }

  void _updateOverlay() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
  }

  Widget _buildSuggestionsList() {
    if (!_showSuggestions) return const SizedBox.shrink();

    // Get screen size for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final textSize = isMobile ? 14.0 : isTablet ? 15.0 : 16.0;
    final subtitleSize = isMobile ? 12.0 : isTablet ? 13.0 : 14.0;
    final iconSize = isMobile ? 20.0 : 24.0;

    if (_isSearching) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Row(
          children: [
            SizedBox(
              width: isMobile ? 16 : 20,
              height: isMobile ? 16 : 20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: Text(
                'Searching locations...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: textSize,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Use current location" option
            ListTile(
              leading: Icon(Icons.my_location, color: widget.iconColor, size: iconSize),
              title: Text('Use current location', style: TextStyle(fontSize: textSize)),
              subtitle: Text('Get your current GPS location', style: TextStyle(fontSize: subtitleSize)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 4 : 8,
              ),
              onTap: () => _useCurrentLocation(),
            ),
            ListTile(
              leading: Icon(Icons.map, color: widget.iconColor.withOpacity(0.9), size: iconSize),
              title: Text('Pick on map', style: TextStyle(fontSize: textSize)),
              subtitle: Text('Tap to select exact point', style: TextStyle(fontSize: subtitleSize)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 4 : 8,
              ),
              onTap: _openMapPicker,
            ),
            if (_searchResults.isNotEmpty) const Divider(height: 1),
            // Search results
            if (_searchResults.isEmpty && _controller.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: iconSize,
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: Text(
                            'No locations found',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: textSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Text(
                      'You can manually enter the address:\nExample: Wanaheda, Street 123, House 45',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: subtitleSize,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        _removeOverlay();
                        _focusNode.unfocus();
                        // Accept the manually entered address
                        if (_controller.text.isNotEmpty) {
                          widget.onLocationSelected(_controller.text, null, null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Using manually entered address'),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.check, size: isMobile ? 16 : 18),
                      label: Text(
                        'Use This Address',
                        style: TextStyle(fontSize: isMobile ? 12 : 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ...(_searchResults
                .take(3)
                .map((place) => _buildSuggestionTile(place))),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(PlaceModel place) {
    // Get screen size for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final titleSize = isMobile ? 14.0 : isTablet ? 15.0 : 16.0;
    final subtitleSize = isMobile ? 12.0 : isTablet ? 13.0 : 14.0;
    final iconSize = isMobile ? 20.0 : 24.0;

    return ListTile(
      leading: Icon(
        Icons.location_on,
        color: widget.iconColor.withOpacity(0.7),
        size: iconSize,
      ),
      title: Text(
        place.mainText,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: titleSize),
      ),
      subtitle: Text(
        place.secondaryText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: subtitleSize),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 4 : 8,
      ),
      onTap: () => _selectPlace(place),
    );
  }

  Future<void> _useCurrentLocation() async {
    _removeOverlay();
    _focusNode.unfocus();

    try {
      // Show loading indicator
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
            _showSuggestions = false;
          });

          widget.onLocationSelected(
            address,
            position.latitude,
            position.longitude,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location found successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('Unable to get address for your location. Please try selecting a location manually.');
        }
      } else {
        throw Exception('Unable to get your current location. Please check your location settings or select a location manually.');
      }
    } catch (e) {
      if (mounted) {
        String message = 'Failed to get current location';
        if (e.toString().contains('permission')) {
          message =
              'Location permission denied. Please enable location access in settings.';
        } else if (e.toString().contains('disabled')) {
          message =
              'Location services are disabled. Please enable them in your device settings.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _useCurrentLocation(),
            ),
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
      _showSuggestions = false;
    });

    double? lat = place.latitude;
    double? lng = place.longitude;

    // If coordinates are not available, try to get them
    if (lat == null || lng == null) {
      // Try geocoding
      final coords = await LocationService.getCoordinatesFromAddress(
        selectedAddress,
      );
      if (coords != null) {
        lat = coords['latitude'];
        lng = coords['longitude'];
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
      // Use Navigator.push with a full-screen route to keep it contained
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
          _showSuggestions = false;
        });
        widget.onLocationSelected(
          selectedAddress,
          result.latitude,
          result.longitude,
        );
      }
    } catch (e) {
      // Handle any navigation errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open map picker. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
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

    // Responsive text sizes
    final textSize = isMobile ? 14.0 : isTablet ? 15.0 : 16.0;
    final labelSize = isMobile ? 14.0 : isTablet ? 15.0 : 16.0;
    final hintSize = isMobile ? 13.0 : isTablet ? 14.0 : 15.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final padding = isMobile ? 12.0 : 16.0;
    final borderRadius = isMobile ? 10.0 : 12.0;

    // For web, use a Column with inline suggestions
    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
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
              helperText: 'You can search or manually enter: Region, Street Name, House #',
              helperStyle: TextStyle(fontSize: isMobile ? 11.0 : 12.0),
              helperMaxLines: 2,
              prefixIcon: Icon(widget.prefixIcon, color: widget.iconColor, size: iconSize),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        widget.onLocationSelected('', null, null);
                        setState(() {
                          _searchResults.clear();
                          _showSuggestions = false;
                        });
                        _removeOverlay();
                      },
                      icon: Icon(Icons.clear, color: widget.iconColor, size: iconSize),
                      tooltip: 'Clear',
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: widget.iconColor, width: 2),
              ),
            ),
            onChanged: (value) {
              _onTextChanged(value);
              // Allow manual entry - accept any non-empty text as valid
              if (value.isNotEmpty && value.length > 5) {
                widget.onLocationSelected(value, null, null);
              }
            },
            onFieldSubmitted: (value) {
              // When user presses done, accept their manual entry
              if (value.isNotEmpty) {
                widget.onLocationSelected(value, null, null);
                _focusNode.unfocus();
              }
            },
            validator: widget.validator,
          ),
          // Show suggestions inline for web
          if (_showSuggestions && _focusNode.hasFocus) ...[
            SizedBox(height: isMobile ? 6 : 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildSuggestionsList(),
              ),
            ),
          ],
        ],
      );
    }

    // For mobile, use the original TextFormField with overlay
    return TextFormField(
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
        helperText: 'You can search or manually enter: Region, Street Name, House #',
        helperStyle: TextStyle(fontSize: isMobile ? 11.0 : 12.0),
        helperMaxLines: 2,
        prefixIcon: Icon(widget.prefixIcon, color: widget.iconColor, size: iconSize),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _controller.clear();
                  widget.onLocationSelected('', null, null);
                  setState(() {
                    _searchResults.clear();
                    _showSuggestions = false;
                  });
                  _removeOverlay();
                },
                icon: Icon(Icons.clear, color: widget.iconColor, size: iconSize),
                tooltip: 'Clear',
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: widget.iconColor, width: 2),
        ),
      ),
      onChanged: (value) {
        _onTextChanged(value);
        // Allow manual entry - accept any non-empty text as valid
        if (value.isNotEmpty && value.length > 5) {
          widget.onLocationSelected(value, null, null);
        }
      },
      onFieldSubmitted: (value) {
        // When user presses done, accept their manual entry
        if (value.isNotEmpty) {
          widget.onLocationSelected(value, null, null);
          _focusNode.unfocus();
        }
      },
      validator: widget.validator,
    );
  }
}
