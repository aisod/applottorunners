import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/global_errand_popup_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'package:lotto_runners/services/errand_acceptance_notification_service.dart';

/// Popup widget that shows "Looking for a runner" when customer requests immediate errand
class LookingForRunnerPopup extends StatefulWidget {
  final String errandId;
  final String errandTitle;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onRunnerFound;

  const LookingForRunnerPopup({
    super.key,
    required this.errandId,
    required this.errandTitle,
    this.onRetry,
    this.onCancel,
    this.onRunnerFound,
  });

  @override
  State<LookingForRunnerPopup> createState() => _LookingForRunnerPopupState();
}

class _LookingForRunnerPopupState extends State<LookingForRunnerPopup>
    with TickerProviderStateMixin {
  Timer? _timeoutTimer;
  Timer? _checkTimer;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  int _timeRemaining = 30; // 30 seconds timeout
  bool _isChecking = true;
  bool _hasTimedOut = false;
  bool _hasShownAcceptanceNotification =
      false; // Prevent duplicate notifications

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    // Start checking for runner
    _startRunnerSearch();
  }

  void _startRunnerSearch() {
    // Start timeout timer
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeRemaining--;
        });

        if (_timeRemaining <= 0) {
          _handleTimeout();
          timer.cancel();
        }
      }
    });

    // Start checking for runner acceptance
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkForRunnerAcceptance();
    });

    // Start cleanup timer to delete expired errands
    Timer.periodic(const Duration(seconds: 10), (timer) {
      ImmediateErrandService.cleanupExpiredErrands();
    });
  }

  Future<void> _checkForRunnerAcceptance() async {
    // Check if widget is still mounted before proceeding
    if (!mounted) {
      print('🔍 [Acceptance] Widget unmounted, skipping check');
      return;
    }

    // Don't check if we've already shown the acceptance notification
    if (_hasShownAcceptanceNotification) {
      print(
          '🔍 [Acceptance] Acceptance notification already shown, skipping check');
      return;
    }

    try {
      // Check if this is a pending ID (starts with "pending_")
      if (widget.errandId.startsWith('pending_')) {
        // For pending IDs, we need to check both pending errands AND accepted errands
        // because once accepted, the errand might be removed from pending list

        // First check pending errands
        final pendingErrands = await ImmediateErrandService.getPendingErrands();

        // Check if still mounted after async operation
        if (!mounted) {
          print(
              '🔍 [Acceptance] Widget unmounted during pending errands query, aborting');
          return;
        }
        print(
            '🔍 [Acceptance] Looking for errand with title: ${widget.errandTitle}');
        print(
            '🔍 [Acceptance] Available pending errands: ${pendingErrands.map((e) => '${e['id']} - ${e['title']} - ${e['status']}').toList()}');

        var matchingErrand = pendingErrands.firstWhere(
          (errand) => errand['title'] == widget.errandTitle,
          orElse: () => <String, dynamic>{},
        );

        // If not found in pending, check accepted errands for this customer
        if (matchingErrand.isEmpty) {
          print(
              '🔍 [Acceptance] Not found in pending, checking accepted errands...');
          final userId = SupabaseConfig.currentUser?.id;
          if (userId != null) {
            final myErrands = await SupabaseConfig.getMyErrands(userId);

            // Check if still mounted after async operation
            if (!mounted) {
              print(
                  '🔍 [Acceptance] Widget unmounted during async operation, aborting');
              return;
            }
            final acceptedErrands = myErrands
                .where((errand) =>
                    errand['title'] == widget.errandTitle &&
                    errand['status'] == 'accepted' &&
                    errand['is_immediate'] == true)
                .toList();

            print(
                '🔍 [Acceptance] Accepted immediate errands: ${acceptedErrands.map((e) => '${e['id']} - ${e['title']} - ${e['status']} - ${e['runner_id']}').toList()}');

            if (acceptedErrands.isNotEmpty) {
              matchingErrand = acceptedErrands.first;
              print(
                  '🔍 [Acceptance] Found accepted errand: ${matchingErrand['id']}');
            }
          }
        }

        print(
            '🔍 [Acceptance] Matching errand found: ${matchingErrand.isNotEmpty ? 'YES' : 'NO'}');
        if (matchingErrand.isNotEmpty) {
          print(
              '🔍 [Acceptance] Errand status: ${matchingErrand['status']}, Runner ID: ${matchingErrand['runner_id']}');
        }

        if (matchingErrand.isNotEmpty &&
            matchingErrand['status'] == 'accepted' &&
            matchingErrand['runner_id'] != null &&
            !_hasShownAcceptanceNotification) {
          // Runner found! Stop the timer and show notification
          _checkTimer?.cancel();
          _timeoutTimer?.cancel();
          _hasShownAcceptanceNotification = true; // Mark as shown

          if (mounted) {
            setState(() {
              _isChecking = false;
            });

            // Get runner information
            final runnerId = matchingErrand['runner_id'];
            final runnerInfo = await SupabaseConfig.client
                .from('users')
                .select('full_name')
                .eq('id', runnerId)
                .single();

            // Check if still mounted after async operation
            if (!mounted) {
              print(
                  '🔍 [Acceptance] Widget unmounted during runner info fetch, aborting');
              return;
            }

            final runnerName = runnerInfo['full_name'] ?? 'Unknown Runner';

            // Show acceptance notification
            ErrandAcceptanceNotificationService.instance
                .showAcceptanceNotification(
              errandId: matchingErrand['id'],
              errandTitle: widget.errandTitle,
              runnerName: runnerName,
            );

            // Show success message briefly
            await Future.delayed(const Duration(milliseconds: 1500));

            if (mounted) {
              widget.onRunnerFound?.call();
            }
          }
        } else if (matchingErrand.isEmpty) {
          // Errand was deleted from database (expired)
          if (mounted) {
            setState(() {
              _isChecking = false;
              _hasTimedOut = true;
            });

            // Stop animations
            _pulseController.stop();
            _rotationController.stop();
          }
        }
      } else {
        // For regular UUIDs, query directly
        final errand = await SupabaseConfig.client
            .from('errands')
            .select('status, runner_id')
            .eq('id', widget.errandId)
            .single();

        // Check if still mounted after async operation
        if (!mounted) {
          print(
              '🔍 [Acceptance] Widget unmounted during errand query, aborting');
          return;
        }

        if (errand['status'] == 'accepted' &&
            errand['runner_id'] != null &&
            !_hasShownAcceptanceNotification) {
          // Runner found! Stop the timer and show notification
          _checkTimer?.cancel();
          _timeoutTimer?.cancel();
          _hasShownAcceptanceNotification = true; // Mark as shown

          if (mounted) {
            setState(() {
              _isChecking = false;
            });

            // Get runner information
            final runnerId = errand['runner_id'];
            final runnerInfo = await SupabaseConfig.client
                .from('users')
                .select('full_name')
                .eq('id', runnerId)
                .single();

            // Check if still mounted after async operation
            if (!mounted) {
              print(
                  '🔍 [Acceptance] Widget unmounted during runner info fetch, aborting');
              return;
            }

            final runnerName = runnerInfo['full_name'] ?? 'Unknown Runner';

            // Show acceptance notification
            ErrandAcceptanceNotificationService.instance
                .showAcceptanceNotification(
              errandId: widget.errandId,
              errandTitle: widget.errandTitle,
              runnerName: runnerName,
            );

            // Show success message briefly
            await Future.delayed(const Duration(milliseconds: 1500));

            if (mounted) {
              widget.onRunnerFound?.call();
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for runner acceptance: $e');

      // Only handle errors if widget is still mounted
      if (!mounted) {
        print(
            '🔍 [Acceptance] Widget unmounted during error handling, aborting');
        return;
      }

      // If errand doesn't exist (deleted), treat as timeout
      if (e.toString().contains('No rows found') ||
          e.toString().contains('PGRST116')) {
        if (mounted) {
          setState(() {
            _isChecking = false;
            _hasTimedOut = true;
          });

          // Stop animations
          _pulseController.stop();
          _rotationController.stop();
        }
      }
    }
  }

  void _handleTimeout() {
    if (mounted) {
      setState(() {
        _isChecking = false;
        _hasTimedOut = true;
      });

      // Stop animations
      _pulseController.stop();
      _rotationController.stop();

      // Auto-dismiss this errand after timeout to prevent it from showing again
      // This ensures that if user doesn't retry, the errand won't keep appearing
      Timer(const Duration(seconds: 5), () {
        if (mounted && _hasTimedOut) {
          GlobalErrandPopupService.instance.dismissErrandById(widget.errandId);
        }
      });
    }
  }

  void _handleRetry() {
    if (mounted) {
      setState(() {
        _isChecking = true;
        _hasTimedOut = false;
        _timeRemaining = 30;
      });

      // Restart animations
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();

      // Restart search
      _startRunnerSearch();

      widget.onRetry?.call();
    }
  }

  void _handleCancel() {
    // If the timer has timed out and user cancels, mark this errand as dismissed
    // to prevent it from showing again in the global popup service
    if (_hasTimedOut) {
      GlobalErrandPopupService.instance.dismissErrandById(widget.errandId);
    }
    widget.onCancel?.call();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _checkTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Looking for a Runner',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Animated search icon
              if (_isChecking) ...[
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_pulseAnimation, _rotationAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_search,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Status text
                Text(
                  'Searching for available runners...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Time remaining
                Text(
                  'Time remaining: $_timeRemaining seconds',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              // Timeout state
              if (_hasTimedOut) ...[
                const Icon(
                  Icons.access_time,
                  size: 60,
                  color: Colors.orange,
                ),

                const SizedBox(height: 16),

                Text(
                  'No runner found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Would you like to retry or cancel your request?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleCancel,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Success state (briefly shown)
              if (!_isChecking && !_hasTimedOut) ...[
                const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'Runner Found!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A runner has accepted your request.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
