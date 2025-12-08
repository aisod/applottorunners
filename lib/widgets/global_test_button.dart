import 'package:flutter/material.dart';
import 'package:lotto_runners/services/global_ride_popup_service.dart';
import 'package:lotto_runners/services/global_errand_popup_service.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

/// Global floating test button that appears on all pages for runners
class GlobalTestButton extends StatelessWidget {
  const GlobalTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton.small(
            onPressed: () {
              GlobalRidePopupService.instance.testPopup();
            },
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            child: const Icon(Icons.directions_car, size: 16),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: () {
              GlobalErrandPopupService.instance.manualCheck();
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            child: const Icon(Icons.work, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Widget that shows global test button only for runners
class GlobalTestButtonWrapper extends StatefulWidget {
  final Widget child;

  const GlobalTestButtonWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalTestButtonWrapper> createState() =>
      _GlobalTestButtonWrapperState();
}

class _GlobalTestButtonWrapperState extends State<GlobalTestButtonWrapper> {
  bool _isRunner = false;

  @override
  void initState() {
    super.initState();
    _checkIfRunner();
  }

  Future<void> _checkIfRunner() async {
    try {
      final profile = await SupabaseConfig.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _isRunner = profile?['user_type'] == 'runner';
        });
      }
    } catch (e) {
      print('Error checking user type: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isRunner) const GlobalTestButton(),
      ],
    );
  }
}
