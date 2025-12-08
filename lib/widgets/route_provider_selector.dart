import 'package:flutter/material.dart';
import '../supabase/supabase_config.dart';

/// Route Provider Selector Widget
///
/// This widget demonstrates how to use the new provider functions
/// to create a dropdown that shows available providers for a selected route.
class RouteProviderSelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onProviderSelected;
  final String? initialRouteId;
  final String? initialRouteName;

  const RouteProviderSelector({
    super.key,
    required this.onProviderSelected,
    this.initialRouteId,
    this.initialRouteName,
  });

  @override
  State<RouteProviderSelector> createState() => _RouteProviderSelectorState();
}

class _RouteProviderSelectorState extends State<RouteProviderSelector> {
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _providers = [];
  String? _selectedRouteId;
  String? _selectedRouteName;
  Map<String, dynamic>? _selectedProvider;
  bool _isLoadingRoutes = true;
  bool _isLoadingProviders = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    if (widget.initialRouteId != null) {
      _selectedRouteId = widget.initialRouteId;
      _loadProvidersForRoute(widget.initialRouteId!);
    }
    if (widget.initialRouteName != null) {
      _selectedRouteName = widget.initialRouteName;
      _loadProvidersForRouteByName(widget.initialRouteName!);
    }
  }

  String _formatOperatingDays(dynamic days) {
    if (days == null) return '';
    final List<dynamic> list =
        days is List ? List<dynamic>.from(days) : <dynamic>[days];
    final Set<int> normalized = list
        .map((d) => d is int
            ? d
            : int.tryParse(d.toString()) ?? _dayNameToInt(d.toString()))
        .where((d) => d > 0 && d <= 7)
        .toSet();
    final List<int> ordered = normalized.toList()..sort();
    return ordered.map(_dayIntToName).join(', ');
  }

  int _dayNameToInt(String name) {
    switch (name.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 0;
    }
  }

  String _dayIntToName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoadingRoutes = true);
    try {
      final routes = await SupabaseConfig.getAllRoutes();
      setState(() {
        _routes = routes;
        _isLoadingRoutes = false;
      });
    } catch (e) {
      print('Error loading routes: $e');
      setState(() => _isLoadingRoutes = false);
    }
  }

  Future<void> _loadProvidersForRoute(String routeId) async {
    setState(() => _isLoadingProviders = true);
    try {
      final providers = await SupabaseConfig.getProvidersForRoute(routeId);
      setState(() {
        _providers = providers;
        _isLoadingProviders = false;
      });
      print('Loaded ${providers.length} providers for route $routeId');
    } catch (e) {
      print('Error loading providers for route: $e');
      setState(() => _isLoadingProviders = false);
    }
  }

  Future<void> _loadProvidersForRouteByName(String routeName) async {
    setState(() => _isLoadingProviders = true);
    try {
      final providers =
          await SupabaseConfig.getProvidersForRouteByName(routeName);
      setState(() {
        _providers = providers;
        _isLoadingProviders = false;
      });
      print('Loaded ${providers.length} providers for route "$routeName"');
    } catch (e) {
      print('Error loading providers for route by name: $e');
      setState(() => _isLoadingProviders = false);
    }
  }

  void _onRouteSelected(String? routeId) {
    setState(() {
      _selectedRouteId = routeId;
      _selectedProvider = null;
      _providers = [];
    });

    if (routeId != null) {
      _loadProvidersForRoute(routeId);
    }
  }

  void _onRouteSelectedByName(String? routeName) {
    setState(() {
      _selectedRouteName = routeName;
      _selectedProvider = null;
      _providers = [];
    });

    if (routeName != null) {
      _loadProvidersForRouteByName(routeName);
    }
  }

  void _onProviderSelected(Map<String, dynamic>? value) {
    setState(() {
      _selectedProvider = value;
    });
    if (value != null) {
      widget.onProviderSelected(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route Select
        DropdownButtonFormField<String>(
          initialValue: _selectedRouteId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Route'),
          items: _routes
              .map((route) => DropdownMenuItem<String>(
                    value: route['id'],
                    child: Text(route['route_name'] ?? 'Unknown Route'),
                  ))
              .toList(),
          onChanged: _onRouteSelected,
        ),
        const SizedBox(height: 16),

        // Provider Select
        if (_isLoadingProviders)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedProvider,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Provider'),
            items: _providers.map((provider) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: provider,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['provider_name'] ?? 'Unknown Provider',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'KSH ${provider['price']?.toStringAsFixed(2) ?? '0.00'} - ${provider['departure_time'] ?? 'N/A'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (provider['operating_days'] != null &&
                        (provider['operating_days'] as List).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Days: ${_formatOperatingDays(provider['operating_days'])}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: _onProviderSelected,
          ),
        if (_selectedProvider != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Provider Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                    'Provider: ${_selectedProvider?['provider_name'] ?? 'Unknown'}'),
                Text(
                    'Price: KSH ${_selectedProvider?['price']?.toStringAsFixed(2) ?? '0.00'}'),
                Text(
                    'Departure: ${_selectedProvider?['departure_time'] ?? 'N/A'}'),
                if (_selectedProvider?['check_in_time'] != null)
                  Text('Check-in: ${_selectedProvider?['check_in_time']}'),
                if (_selectedProvider?['operating_days'] != null)
                  Text(
                      'Days: ${_formatOperatingDays(_selectedProvider?['operating_days'])}'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
