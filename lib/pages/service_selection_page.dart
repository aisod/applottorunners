import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/pages/queue_sitting_form_page.dart';
import 'package:lotto_runners/pages/license_discs_form_page.dart';
import 'package:lotto_runners/pages/shopping_form_page.dart';
import 'package:lotto_runners/pages/delivery_form_page.dart';
import 'package:lotto_runners/pages/document_services_form_page.dart';
import 'package:lotto_runners/pages/elderly_services_form_page.dart';
import 'package:lotto_runners/pages/enhanced_post_errand_form_page.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/service_icons.dart';
import 'package:lotto_runners/utils/page_transitions.dart';

class ServiceSelectionPage extends StatefulWidget {
  const ServiceSelectionPage({super.key});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoadingServices = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final profile = await SupabaseConfig.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
          });
          // Reload services after profile is loaded to apply proper filtering
          _loadServices();
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Get the appropriate price for a service based on user type
  double _getServicePrice(Map<String, dynamic> service) {
    double price;
    if (_userProfile != null && _userProfile!['user_type'] == 'business') {
      price = (service['business_price'] ?? service['base_price'] ?? 0.0)
          .toDouble();
    } else {
      price = (service['base_price'] ?? 0.0).toDouble();
    }
    
    // Apply discount if available
    final discountPercentage = (service['discount_percentage'] ?? 0.0).toDouble();
    if (discountPercentage > 0) {
      return SupabaseConfig.calculateDiscountedPrice(price, discountPercentage);
    }
    
    return price;
  }

  // Get original price before discount
  double _getOriginalPrice(Map<String, dynamic> service) {
    if (_userProfile != null && _userProfile!['user_type'] == 'business') {
      return (service['business_price'] ?? service['base_price'] ?? 0.0)
          .toDouble();
    }
    return (service['base_price'] ?? 0.0).toDouble();
  }

  Future<void> _loadServices() async {
    try {
      setState(() => _isLoadingServices = true);
      final services = await SupabaseConfig.getServices();

      if (mounted) {
        // Check if user is a business user
        final isBusinessUser = _userProfile != null && 
                               _userProfile!['user_type'] == 'business';

        // Filter out registration services and elderly services for business users
        final filteredServices = services.where((service) {
          final category = service['category']?.toString().toLowerCase() ?? '';
          final name = service['name']?.toString().toLowerCase() ?? '';
          
          // Exclude registration services
          if (category.contains('registration') || name.contains('registration')) {
            return false;
          }
          
          // Exclude elderly services for business users only
          if (isBusinessUser && 
              (category.contains('elderly') || name.contains('elderly'))) {
            return false;
          }
          
          return true;
        }).toList();

        setState(() {
          _services = filteredServices;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingServices = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading services: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Icon mapping moved to ServiceIcons utility for consistency across app.

  void _selectService(Map<String, dynamic> service) {
    Widget destinationPage;

    // Route to specific forms based on service category
    switch (service['category']) {
      case 'queue_sitting':
        destinationPage = QueueSittingFormPage(
          selectedService: service,
          userProfile: _userProfile,
        );
        break;
      case 'license_discs':
        destinationPage = LicenseDiscsFormPage(
          selectedService: service,
          userProfile: _userProfile,
        );
        break;
      case 'shopping':
        destinationPage = ShoppingFormPage(
          selectedService: service,
          userProfile: _userProfile,
        );
        break;
      case 'delivery':
        destinationPage = DeliveryFormPage(
          selectedService: service,
          userProfile: _userProfile,
        );
        break;
      case 'document_services':
        destinationPage = DocumentServicesFormPage(
          selectedService: service,
          userProfile: _userProfile,
        );
        break;
      case 'elderly_services':
        destinationPage = ElderlyServicesFormPage(
          selectedService: service,
          userProfile: _userProfile,
        );
        break;
      default:
        // Fallback to enhanced form for any unhandled categories
        destinationPage = EnhancedPostErrandFormPage(
          selectedService: service,
          userProfile: _userProfile,
        );
        break;
    }

    Navigator.push(
      context,
      PageTransitions.slideAndFade(destinationPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Service Type',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : isTablet ? 20 : 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: LottoRunnersColors.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadServices,
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
            tooltip: 'Refresh Services',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(theme, isMobile, isTablet, isDesktop),
      ),
    );
  }

  Widget _buildBody(
      ThemeData theme, bool isMobile, bool isTablet, bool isDesktop) {
    if (_isLoadingServices) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_services.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: isMobile ? 56 : 64,
                color: theme.colorScheme.outline,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'No services available',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: isMobile ? 20 : isTablet ? 22 : 24,
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Please contact an administrator to set up services',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline.withOpacity(0.7),
                  fontSize: isMobile ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 20 : 24),
              ElevatedButton.icon(
                onPressed: _loadServices,
                icon: Icon(Icons.refresh, size: isMobile ? 18 : 20),
                label: Text(
                  'Retry',
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine padding based on device size
    final double padding = isMobile ? 16.0: isTablet ? 24.0 : 32.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose the type of service you need',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: isMobile ? 15 : isTablet ? 16 : 17,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Expanded(
            child: ListView.builder(
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                return _buildServiceCard(
                    theme, service, isMobile, isTablet, isDesktop);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Get the appropriate icon image URL for a service category
  String? _getServiceIconUrl(String? category) {
    const baseUrl = 'https://irfbqpruvkkbylwwikwx.supabase.co/storage/v1/object/public/icons';
    
    switch (category) {
      case 'delivery':
        return '$baseUrl/truck.png';
      case 'elderly_services':
        return '$baseUrl/elderly.png';
      case 'license_discs':
        return '$baseUrl/vehicle.png';
      case 'document_services':
        return '$baseUrl/document.png';
      case 'queue_sitting':
        return '$baseUrl/queue.png';
      case 'shopping':
        return '$baseUrl/shop.png';
      case 'special_orders':
        return '$baseUrl/special.png';
      default:
        return null; // Use Material icon
    }
  }

  // Get background color for service category
  Color _getServiceColor(String? category) {
    final theme = Theme.of(context);
    
    switch (category) {
      case 'delivery':
        return LottoRunnersColors.accent; // Green
      case 'shopping':
        return LottoRunnersColors.primaryBlue;
      case 'queue_sitting':
        return theme.colorScheme.secondary;
      case 'license_discs':
        return theme.colorScheme.error;
      case 'document_services':
        return LottoRunnersColors.orange;
      case 'elderly_services':
        return theme.colorScheme.tertiary;
      case 'special_orders':
        return LottoRunnersColors.primaryYellow;
      default:
        return LottoRunnersColors.primaryBlue;
    }
  }

  Widget _buildServiceCard(ThemeData theme, Map<String, dynamic> service,
      bool isMobile, bool isTablet, bool isDesktop) {
    final price = _getServicePrice(service);
    final iconUrl = _getServiceIconUrl(service['category']);
    final serviceColor = _getServiceColor(service['category']);
    final iconSize = isMobile ? 50.0 : isTablet ? 56.0 : 60.0;
    final fallbackIconSize = isMobile ? 24.0 : isTablet ? 28.0 : 30.0;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        ),
        child: InkWell(
          onTap: () => _selectService(service),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
            child: Row(
              children: [
                // Icon container with colored background
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: serviceColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  ),
                  child: iconUrl != null
                      ? _buildServiceIcon(iconUrl, isMobile, isTablet, service, iconSize)
                      : Icon(
                          ServiceIcons.getIcon(service['icon_name']),
                          color: serviceColor,
                          size: fallbackIconSize,
                        ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] ?? 'Unknown Service',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                        ),
                      ),
                      SizedBox(height: isMobile ? 3 : 4),
                      Text(
                        service['description'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: isMobile ? 11 : isTablet ? 12 : 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                // Price and arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Check if service has discount
                    if (service['discount_percentage'] != null &&
                        service['discount_percentage'] > 0) ...[
                      // Show original price crossed out
                      Text(
                        'N\$${_getOriginalPrice(service).toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w400,
                          fontSize: isMobile ? 11 : isTablet ? 12 : 13,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      // Show discounted price
                      Text(
                        (service['category'] == 'delivery' || service['category'] == 'special_orders' || service['category'] == 'license_discs')
                            ? 'Varies'
                            : 'N\$${price.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                        ),
                      ),
                      // Show discount badge
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${service['discount_percentage'].toStringAsFixed(0)}% OFF',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 9 : 10,
                          ),
                        ),
                      ),
                    ] else
                      Text(
                        (service['category'] == 'delivery' || service['category'] == 'special_orders' || service['category'] == 'license_discs')
                            ? 'Varies'
                            : 'N\$${price.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: LottoRunnersColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                        ),
                      ),
                    if (service['requires_vehicle']) ...[
                      SizedBox(height: isMobile ? 3 : 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 5 : 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: isMobile ? 9 : 10,
                              color: theme.colorScheme.error,
                            ),
                            SizedBox(width: isMobile ? 2 : 3),
                            Text(
                              'Vehicle',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontSize: isMobile ? 8 : 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: isMobile ? 14 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon(String iconUrl, bool isMobile, bool isTablet, Map<String, dynamic> service, double iconSize) {
    final serviceColor = _getServiceColor(service['category']);
    final fallbackIconSize = isMobile ? 24.0 : isTablet ? 28.0 : 30.0;
    final loadingSize = isMobile ? 16.0 : 20.0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      child: Image.network(
        iconUrl,
        fit: BoxFit.cover,
        width: iconSize,
        height: iconSize,
        cacheWidth: 128,
        cacheHeight: 128,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: loadingSize,
              height: loadingSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: serviceColor,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback to Material icon if image fails to load
          return Icon(
            ServiceIcons.getIcon(service['icon_name']),
            color: serviceColor,
            size: fallbackIconSize,
          );
        },
      ),
    );
  }
}
