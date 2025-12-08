import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../theme.dart';

/// A custom location input field with Google Places Autocomplete integration
///
/// This widget provides:
/// - Real-time location suggestions as the user types
/// - Current location detection
/// - Google Places API integration
/// - Fallback to basic geocoding when API is unavailable
class LocationInputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final VoidCallback? onLocationChanged;
  final bool isRequired;
  final bool showCurrentLocationButton;

  const LocationInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.controller,
    this.validator,
    this.onLocationChanged,
    this.isRequired = true,
    this.showCurrentLocationButton = true,
  });

  @override
  State<LocationInputField> createState() => _LocationInputFieldState();
}

class _LocationInputFieldState extends State<LocationInputField> {
  List<PlaceModel> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && widget.controller.text.isNotEmpty) {
      _showSuggestions = true;
      _searchPlaces(widget.controller.text);
    } else {
      _showSuggestions = false;
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    if (_focusNode.hasFocus && widget.controller.text.isNotEmpty) {
      _searchPlaces(widget.controller.text);
    } else {
      _showSuggestions = false;
      _removeOverlay();
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final places = await LocationService.searchPlaces(query);
      setState(() {
        _suggestions = places;
        _showSuggestions = places.isNotEmpty;
        _isLoading = false;
      });

      if (_showSuggestions) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _suggestions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (!mounted || !_showSuggestions) return;

    // Use a more stable positioning approach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: position.dy + size.height + 8,
          left: position.dx,
          width: size.width,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            suggestion.mainText.isNotEmpty
                                ? suggestion.mainText
                                : suggestion.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: suggestion.secondaryText.isNotEmpty
                              ? Text(
                                  suggestion.secondaryText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                )
                              : null,
                          leading: const Icon(Icons.location_on, size: 20),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      },
                    ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getFieldBottomPosition() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    // Account for scroll position by using the global position
    return position.dy + renderBox.size.height + 8;
  }

  double _getFieldLeftPosition() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    // Use global position to avoid scroll displacement
    return position.dx;
  }

  double _getFieldWidth() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    return renderBox.size.width;
  }

  void _selectSuggestion(PlaceModel suggestion) {
    widget.controller.text = suggestion.description;
    _showSuggestions = false;
    _removeOverlay();
    _focusNode.unfocus();

    if (widget.onLocationChanged != null) {
      widget.onLocationChanged!();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (address != null) {
          widget.controller.text = address;
          if (widget.onLocationChanged != null) {
            widget.onLocationChanged!();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting current location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label + (widget.isRequired ? ' *' : ''),
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: widget.showCurrentLocationButton
                ? IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Use current location',
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          validator: widget.validator,
          onChanged: (value) {
            if (widget.onLocationChanged != null) {
              widget.onLocationChanged!();
            }
          },
        ),
        if (_isLoading && _suggestions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      LottoRunnersColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Searching locations...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
