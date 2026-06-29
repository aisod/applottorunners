import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks device network connectivity for offline UI and request guards.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
    _checkInitial();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> _checkInitial() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateFromResults(results);
    } catch (_) {
      _isOnline = true;
    }
  }

  void _onChanged(List<ConnectivityResult> results) {
    _updateFromResults(results);
  }

  void _updateFromResults(List<ConnectivityResult> results) {
    final online = kIsWeb
        ? true
        : results.any(
            (r) =>
                r == ConnectivityResult.mobile ||
                r == ConnectivityResult.wifi ||
                r == ConnectivityResult.ethernet ||
                r == ConnectivityResult.vpn,
          );
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  /// Throws if offline (use before network writes).
  void ensureOnline() {
    if (!_isOnline) {
      throw Exception('NETWORK_ERROR: No internet connection');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
