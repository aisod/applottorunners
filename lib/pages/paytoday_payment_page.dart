import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows;
import 'package:url_launcher/url_launcher.dart';
import 'package:lotto_runners/services/paytoday_config.dart';
import 'package:lotto_runners/services/paytoday_backend_service.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';

/// PayToday Payment Page
/// Displays a WebView to handle PayToday payment flow
class PayTodayPaymentPage extends StatefulWidget {
  final String errandId;
  final double amount;
  final String paymentType;
  final String customerId;
  final String? runnerId;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;
  final VoidCallback? onCancel;

  const PayTodayPaymentPage({
    super.key,
    required this.errandId,
    required this.amount,
    required this.paymentType,
    required this.customerId,
    this.runnerId,
    this.onSuccess,
    this.onFailure,
    this.onCancel,
  });

  @override
  State<PayTodayPaymentPage> createState() => _PayTodayPaymentPageState();
}

class _PayTodayPaymentPageState extends State<PayTodayPaymentPage> {
  // Mobile controller
  late WebViewController _mobileController;
  // Windows controller
  final _windowsController = windows.WebviewController();
  
  bool _isLoading = true;
  bool _isInitializing = true;
  String? _errorMessage;
  double _loadingProgress = 0.0;
  bool _isWindows = false;
  String? _paymentDataUri;

  @override
  void initState() {
    super.initState();
    // Safety check for Web and platform
    if (!kIsWeb) {
      try {
        _isWindows = Platform.isWindows;
      } catch (e) {
        _isWindows = false;
      }
    }
    _initializePayment();
  }

  @override
  void dispose() {
    if (_isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  Future<void> _initializePayment() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      PayTodayConfig.log('Initializing payment page');

      // Create payment intent
      final intentData = await PayTodayBackendService.createPaymentIntent(
        errandId: widget.errandId,
        amount: widget.amount,
        paymentType: widget.paymentType,
        customerId: widget.customerId,
        runnerId: widget.runnerId,
      );

      // Get data URI from response
      final dataUri = intentData['data_uri'] as String?;
      if (dataUri == null) {
        throw Exception('No data URI received from payment intent');
      }

      if (kIsWeb) {
        await _initializeWebPayment(dataUri);
      } else if (_isWindows) {
        await _initializeWindowsWebView(dataUri);
      } else {
        await _initializeMobileWebView(dataUri);
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      PayTodayConfig.logError('Failed to initialize payment', e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to initialize payment: ${e.toString()}';
        });
      }

      // Report failure to backend
      await PayTodayBackendService.reportFailure(
        errandId: widget.errandId,
        paymentType: widget.paymentType,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _initializeWebPayment(String dataUri) async {
    // For Web, we store the URI and wait for user to click "Pay Now"
    // browsers block window.open if not triggered by a user gesture.
    setState(() {
      _paymentDataUri = dataUri;
      _isLoading = false;
    });
    PayTodayConfig.log('Web Payment URI ready, waiting for user gesture');
  }

  Future<void> _launchWebPayment() async {
    // For Web, we use a standard URL that returns the payment form
    // This avoids "about:blank" issues with long data URIs
    final baseUrl = '${SupabaseConfig.supabaseUrl}/functions/v1/paytoday-create-intent';
    
    final queryParams = {
      'errand_id': widget.errandId,
      'amount': widget.amount.toString(),
      'currency': PayTodayConfig.currency,
      'payment_type': widget.paymentType,
      'return_url': PayTodayConfig.getSuccessUrl(widget.errandId, widget.paymentType),
      'apikey': SupabaseConfig.supabaseAnonKey,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    
    try {
      PayTodayConfig.log('Launching Web payment URL: $uri');
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Could not launch payment URL. Please check your browser popup blocker.');
      }
    } catch (e) {
      PayTodayConfig.logError('Failed to launch web payment', e);
      setState(() {
        _errorMessage = 'Failed to launch payment: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyWebPayment() async {
    setState(() => _isLoading = true);
    try {
      // Find the transaction record to see its status
      final tx = await PayTodayBackendService.getTransaction(
        errandId: widget.errandId,
        paymentType: widget.paymentType,
      );

      if (tx != null && tx['status'] == PayTodayConfig.statusCompleted) {
        _handlePaymentSuccess(Uri.parse('lottorunners://payment/success'));
      } else {
        // Try manual verification via backend
        final result = await PayTodayBackendService.verifyPayment(
          errandId: widget.errandId,
          transactionId: tx?['transaction_id'] ?? 'pending',
        );

        if (result['verified'] == true) {
          _handlePaymentSuccess(Uri.parse('lottorunners://payment/success'));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment not yet verified. Please complete payment or try again in a moment.')),
          );
        }
      }
    } catch (e) {
      PayTodayConfig.logError('Manual verification failed', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeWindowsWebView(String dataUri) async {
    await _windowsController.initialize();
    
    _windowsController.url.listen((url) {
      PayTodayConfig.log('Windows Navigation: $url');
      if (url.startsWith('lottorunners://payment/')) {
        _handleReturnUrl(url);
      }
    });

    _windowsController.loadingState.listen((state) {
        if (state == windows.LoadingState.navigationCompleted) {
            setState(() => _isLoading = false);
        } else if (state == windows.LoadingState.loading) {
            setState(() => _isLoading = true);
        }
    });

    await _windowsController.loadUrl(dataUri);
  }

  Future<void> _initializeMobileWebView(String dataUri) async {
      // Initialize WebView controller
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              setState(() {
                _loadingProgress = progress / 100;
              });
            },
            onPageStarted: (String url) {
              PayTodayConfig.log('Page started: $url');
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              PayTodayConfig.log('Page finished: $url');
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              PayTodayConfig.logError('WebView error', error.description);
              _handleWebViewError(error.description);
            },
            onNavigationRequest: (NavigationRequest request) {
              PayTodayConfig.log('Navigation request: ${request.url}');
              
              // Check if this is a return URL
              if (request.url.startsWith('lottorunners://payment/')) {
                _handleReturnUrl(request.url);
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(dataUri));
  }

  void _handleReturnUrl(String url) {
    PayTodayConfig.log('Handling return URL: $url');

    final uri = Uri.parse(url);
    final path = uri.path;

    if (path.contains('/success')) {
      _handlePaymentSuccess(uri);
    } else if (path.contains('/failure')) {
      _handlePaymentFailure(uri);
    } else if (path.contains('/cancel')) {
      _handlePaymentCancel(uri);
    }
  }

  Future<void> _handlePaymentSuccess(Uri uri) async {
    PayTodayConfig.log('Payment successful');

    try {
      // Extract transaction ID from URL if available
      final transactionId = uri.queryParameters['transaction_id'];

      // Update transaction status
      await PayTodayBackendService.updateTransactionStatus(
        errandId: widget.errandId,
        paymentType: widget.paymentType,
        status: PayTodayConfig.statusCompleted,
        transactionId: transactionId,
      );

      // Show success message
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      PayTodayConfig.logError('Error handling payment success', e);
      _showErrorDialog('Payment completed but failed to update status');
    }
  }

  Future<void> _handlePaymentFailure(Uri uri) async {
    PayTodayConfig.log('Payment failed');

    try {
      final errorMessage = uri.queryParameters['error'] ?? 'Payment failed';

      // Update transaction status
      await PayTodayBackendService.updateTransactionStatus(
        errandId: widget.errandId,
        paymentType: widget.paymentType,
        status: PayTodayConfig.statusFailed,
        errorMessage: errorMessage,
      );

      // Report failure
      await PayTodayBackendService.reportFailure(
        errandId: widget.errandId,
        paymentType: widget.paymentType,
        errorMessage: errorMessage,
      );

      if (mounted) {
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      PayTodayConfig.logError('Error handling payment failure', e);
      if (mounted) {
        _showErrorDialog('Payment failed');
      }
    }
  }

  Future<void> _handlePaymentCancel(Uri uri) async {
    PayTodayConfig.log('Payment cancelled');

    try {
      // Update transaction status
      await PayTodayBackendService.updateTransactionStatus(
        errandId: widget.errandId,
        paymentType: widget.paymentType,
        status: PayTodayConfig.statusFailed,
        errorMessage: 'Payment cancelled by user',
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCancel?.call();
      }
    } catch (e) {
      PayTodayConfig.logError('Error handling payment cancel', e);
      if (mounted) {
        Navigator.pop(context);
        widget.onCancel?.call();
      }
    }
  }

  Future<void> _handleWebViewError(String errorDescription) async {
    await PayTodayBackendService.reportFailure(
      errandId: widget.errandId,
      paymentType: widget.paymentType,
      errorMessage: 'WebView error: $errorDescription',
    );

    if (mounted) {
      setState(() {
        _errorMessage = errorDescription;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: LottoRunnersColors.accent, size: 32),
            const SizedBox(width: 12),
            const Text('Payment Successful'),
          ],
        ),
        content: Text(
          widget.paymentType == PayTodayConfig.paymentTypeFirstHalf
              ? 'First payment completed successfully!'
              : 'Final payment completed successfully!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close payment page
              widget.onSuccess?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LottoRunnersColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            const Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close payment page
              widget.onFailure?.call();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _initializePayment(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LottoRunnersColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LottoRunnersColors.gray50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: LottoRunnersColors.primaryBlue,
        title: const Text(
          'Complete Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            _handlePaymentCancel(Uri.parse('lottorunners://payment/cancel'));
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return _buildLoadingState('Initializing payment...');
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_isWindows) {
      return Stack(
        children: [
      windows.Webview(
        _windowsController,
        permissionRequested: _onPermissionRequested,
      ),
            if (_isLoading) _buildLoadingOverlay(),
        ],
      );
    }

    if (kIsWeb) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _paymentDataUri == null ? Icons.hourglass_empty : Icons.account_balance_wallet,
                size: 64,
                color: LottoRunnersColors.primaryBlue,
              ),
              const SizedBox(height: 24),
              Text(
                _paymentDataUri == null ? 'Preparing Payment...' : 'Ready to Pay',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'On Web, you must manually initiate the payment to open a secure tab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: LottoRunnersColors.gray600),
              ),
              const SizedBox(height: 32),
              if (_paymentDataUri != null) ...[
                ElevatedButton.icon(
                  onPressed: _launchWebPayment,
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text('OPEN SECURE PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LottoRunnersColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(250, 50),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                const Text(
                  'Once you have finished paying in the other tab:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _verifyWebPayment,
                  icon: const Icon(Icons.verified),
                  label: const Text('I HAVE PAID - CHECK STATUS'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(250, 50),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => _handlePaymentCancel(Uri.parse('lottorunners://payment/cancel')),
                child: const Text('Cancel Payment'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _mobileController),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Future<windows.WebviewPermissionDecision> _onPermissionRequested(String url, windows.WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<windows.WebviewPermissionDecision>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView Permission'),
        content: Text('WebView requesting permission for $kind'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, windows.WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, windows.WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? windows.WebviewPermissionDecision.deny;
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(LottoRunnersColors.primaryBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: LottoRunnersColors.gray700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: NAD ${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              color: LottoRunnersColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              valueColor: const AlwaysStoppedAnimation(LottoRunnersColors.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading payment page...',
              style: const TextStyle(
                color: LottoRunnersColors.gray700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: LottoRunnersColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LottoRunnersColors.gray600,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onFailure?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: LottoRunnersColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _initializePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LottoRunnersColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
