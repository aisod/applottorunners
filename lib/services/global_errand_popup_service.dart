import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/widgets/new_errand_request_popup.dart';
import 'package:lotto_runners/services/notification_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'package:lotto_runners/utils/app_log.dart';

/// Global service to manage errand request popups across the entire app
class GlobalErrandPopupService {
  static GlobalErrandPopupService? _instance;
  static GlobalErrandPopupService get instance =>
      _instance ??= GlobalErrandPopupService._();

  GlobalErrandPopupService._();

  Timer? _checkTimer;
  BuildContext? _currentContext;
  OverlayEntry? _currentPopup;
  Map<String, dynamic>? _currentRequest;
  bool _isInitialized = false;

  /// Track dismissed errand requests to prevent re-showing them
  final Set<String> _dismissedErrands = {};
  final Set<String> _declinedErrands = {};

  /// Initialize the service with the current context
  void initialize(BuildContext context) {
    _currentContext = context;
    if (!_isInitialized) {
      _startPolling();
      _isInitialized = true;
      appLog('🌍 Global errand popup service initialized');
    }
  }

  /// Update context when navigating between pages
  void updateContext(BuildContext context) {
    _currentContext = context;
  }

  /// Start polling for new errand requests
  void _startPolling() {
    _checkTimer?.cancel();

    appLog('⏱️ [Global] Starting errand request polling every 30 seconds');
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentContext != null) {
        _checkForNewErrandRequests();
      } else {
        appLog('❌ [Global] No context available, stopping timer');
        timer.cancel();
      }
    });
  }

  /// Check for new errand requests
  Future<void> _checkForNewErrandRequests() async {
    try {
      // Clean up expired immediate errands first
      await ImmediateErrandService.cleanupExpiredErrands();

      // Skip if popup is already showing
      if (_currentPopup != null) {
        appLog('⏭️ [Global] Skipping check - popup already visible');
        return;
      }

      appLog('🔍 [Global] Checking for new errand requests...');

      final user = SupabaseConfig.currentUser;
      if (user == null) {
        appLog('❌ [Global] No current user - skipping errand request check');
        return;
      }

      appLog('👤 [Global] Current user ID: ${user.id}');

      // Check if user has a runner application (approved or pending)
      final runnerApp = await SupabaseConfig.client
          .from('runner_applications')
          .select('verification_status')
          .eq('user_id', user.id)
          .maybeSingle();

      if (runnerApp == null) {
        appLog(
            '❌ [Global] User has no runner application - skipping global errand popup service');
        return;
      }

      appLog(
          '👤 [Global] Runner application status: ${runnerApp['verification_status']}');

      // Additional check: Get complete user profile to ensure they're actually a runner
      final userProfile = await SupabaseConfig.getCompleteUserProfile(user.id);
      if (userProfile == null) {
        appLog(
            '❌ [Global] Could not get user profile - skipping global errand popup service');
        return;
      }

      if (userProfile['user_type'] != 'runner') {
        appLog(
            '❌ [Global] User is not a runner type (${userProfile['user_type']}) - skipping global errand popup service');
        return;
      }

      appLog(
          '✅ [Global] User is a runner - proceeding with errand popup service');

      // Get runner's vehicle type for filtering
      final runnerVehicleType = userProfile['vehicle_type']?.toString() ?? '';
      final hasVehicle = userProfile['has_vehicle'] ?? false;

      appLog(
          '🚗 [Global] Runner vehicle info - has_vehicle: $hasVehicle, vehicle_type: "$runnerVehicleType"');
      appLog('🚗 [Global] Runner profile keys: ${userProfile.keys.toList()}');
      appLog('🚗 [Global] Runner user_type: ${userProfile['user_type']}');

      // Get pending immediate errands
      appLog('🔍 [Global] Querying database for immediate errands...');
      final errands = await SupabaseConfig.client
          .from('errands')
          .select('''
            *,
            user:users!errands_customer_id_fkey(full_name, email, phone)
          ''')
          .eq('status', 'posted')
          .eq('is_immediate', true)
          .filter('runner_id', 'is', null)
          .order('created_at', ascending: false);

      appLog('📋 [Global] Found ${errands.length} pending immediate errands');

      // Debug: Print details of each errand
      for (var errand in errands) {
        appLog(
            '📋 [Global] Errand: ${errand['id']} - ${errand['title']} - vehicle_type: "${errand['vehicle_type']}"');
      }

      // Filter errands based on vehicle type matching
      final filteredErrands = errands.where((errand) {
        final errandVehicleType = errand['vehicle_type']?.toString() ?? '';

        appLog(
            '🔍 [Global] Checking errand: ${errand['title']} - errand vehicle: "$errandVehicleType"');

        // If errand has no vehicle type, any runner can do it
        if (errandVehicleType.isEmpty) {
          appLog(
              '✅ [Global] Errand has no vehicle type - showing to all runners');
          return true;
        }

        // If errand has a vehicle type, only show to runners with matching vehicle type
        if (runnerVehicleType.isEmpty) {
          appLog(
              '❌ [Global] Runner has no vehicle type, can\'t do vehicle errands');
          return false; // Runner has no vehicle type, can't do vehicle errands
        }

        final matches =
            errandVehicleType.toLowerCase() == runnerVehicleType.toLowerCase();
        appLog(
            '${matches ? "✅" : "❌"} [Global] Vehicle type match: "$errandVehicleType" vs "$runnerVehicleType"');
        return matches;
      }).toList();

      appLog(
          '🚗 [Global] After vehicle filtering: ${filteredErrands.length} errands match runner vehicle type: $runnerVehicleType');

      for (final errand in filteredErrands) {
        // Check if this errand was dismissed or declined recently
        final errandId = errand['id'];
        if (_dismissedErrands.contains(errandId)) {
          appLog('⏭️ [Global] Skipping dismissed errand: $errandId');
          continue;
        }
        if (_declinedErrands.contains(errandId)) {
          appLog('⏭️ [Global] Skipping declined errand: $errandId');
          continue;
        }

        // Check if this is a new errand (not the current one)
        if (_currentRequest?['id'] != errand['id']) {
          appLog('🎉 [Global] New matching errand found! Showing popup...');
          appLog(
              '🎉 [Global] Errand details: ${errand['title']} - ${errand['vehicle_type']}');
          _showErrandRequestPopup(errand);
          break;
        } else {
          appLog(
              '⏭️ [Global] Errand ${errand['id']} is already being shown as popup');
        }
      }
    } catch (e) {
      appLog('❌ [Global] Error checking for errand requests: $e');
    }
  }

  /// Show errand request popup globally
  void _showErrandRequestPopup(Map<String, dynamic> errand) {
    if (_currentContext == null) {
      appLog('❌ [Global] Cannot show popup - no context available');
      return;
    }

    appLog(
        '🚨 [Global] Showing errand request popup for errand: ${errand['id']}');
    appLog('🚨 [Global] Errand title: ${errand['title']}');
    appLog('🚨 [Global] Errand vehicle type: ${errand['vehicle_type']}');
    appLog('🚨 [Global] Current context: ${_currentContext.runtimeType}');

    // Hide any existing popup
    hidePopup();

    _currentRequest = errand;

    // Create overlay entry
    _currentPopup = OverlayEntry(
      builder: (context) => NewErrandRequestPopup(
        errand: errand,
        onAccept: () => _acceptErrandRequest(errand),
        onDecline: () => _declineErrandRequest(),
        onDismiss: () => _dismissErrandRequest(),
      ),
    );

    // Insert into overlay
    try {
      Overlay.of(_currentContext!).insert(_currentPopup!);
      appLog('✅ [Global] Popup inserted into overlay successfully');
    } catch (e) {
      appLog('❌ [Global] Error inserting popup into overlay: $e');
    }

    // Auto-dismiss after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (_currentPopup != null && _currentRequest?['id'] == errand['id']) {
        hidePopup();
      }
    });
  }

  /// Accept errand request
  Future<void> _acceptErrandRequest(Map<String, dynamic> errand) async {
    try {
      appLog('✅ [Global] Accepting errand request: ${errand['id']}');

      await SupabaseConfig.acceptErrand(
          errand['id'], SupabaseConfig.currentUser!.id);

      // Show success notification
      await NotificationService.showNotification(
        title: 'Errand Accepted!',
        body: 'You have accepted the errand: ${errand['title']}',
      );

      // Show success snackbar
      if (_currentContext != null) {
        ScaffoldMessenger.of(_currentContext!).showSnackBar(
          const SnackBar(
            content: Text('✅ Errand request accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      hidePopup();
    } catch (e) {
      appLog('❌ [Global] Error accepting errand: $e');

      // Show error snackbar
      if (_currentContext != null) {
        ScaffoldMessenger.of(_currentContext!).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to accept errand: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Decline errand request
  void _declineErrandRequest() {
    appLog('❌ [Global] Errand request declined');

    // Add to declined errands to prevent re-showing
    if (_currentRequest != null) {
      final errandId = _currentRequest!['id'];
      _declinedErrands.add(errandId);
      appLog('🚫 [Global] Added errand $errandId to declined list');
    }

    hidePopup();
  }

  /// Dismiss errand request
  void _dismissErrandRequest() {
    appLog('👋 [Global] Errand request dismissed');

    // Add to dismissed errands to prevent re-showing
    if (_currentRequest != null) {
      final errandId = _currentRequest!['id'];
      _dismissedErrands.add(errandId);
      appLog('⏸️ [Global] Added errand $errandId to dismissed list');
    }

    hidePopup();
  }

  /// Dismiss a specific errand request by ID (public method)
  void dismissErrandById(String errandId) {
    appLog('👋 [Global] Dismissing errand request by ID: $errandId');
    _dismissedErrands.add(errandId);
    appLog('⏸️ [Global] Added errand $errandId to dismissed list');
  }

  /// Hide the current popup
  void hidePopup() {
    _currentPopup?.remove();
    _currentPopup = null;
    _currentRequest = null;
  }

  /// Manual check for new errand requests (for debug purposes)
  Future<void> manualCheck() async {
    appLog('🔍 [Global] Manual check triggered');
    await _checkForNewErrandRequests();
  }

  /// Get status information about dismissed/declined errands (for debug)
  Map<String, dynamic> getDismissedErrandsStatus() {
    return {
      'dismissed_count': _dismissedErrands.length,
      'declined_count': _declinedErrands.length,
      'dismissed_errands': _dismissedErrands.toList(),
      'declined_errands': _declinedErrands.toList(),
    };
  }

  /// Clear all dismissed and declined errand tracking
  void clearDismissedErrands() {
    _dismissedErrands.clear();
    _declinedErrands.clear();
    appLog('🧹 [Global] Cleared dismissed and declined errand tracking');
  }

  /// Dispose resources
  void dispose() {
    _checkTimer?.cancel();
    hidePopup();
    clearDismissedErrands();
    _currentContext = null;
    _isInitialized = false;
    appLog('🌍 Global errand popup service disposed');
  }
}

/// Widget to integrate global errand popup service into any page
class GlobalErrandPopupWrapper extends StatefulWidget {
  final Widget child;

  const GlobalErrandPopupWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalErrandPopupWrapper> createState() =>
      _GlobalErrandPopupWrapperState();
}

class _GlobalErrandPopupWrapperState extends State<GlobalErrandPopupWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalErrandPopupService.instance.initialize(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    GlobalErrandPopupService.instance.updateContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
