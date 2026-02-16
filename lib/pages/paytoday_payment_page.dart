import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows;
import 'package:url_launcher/url_launcher.dart';
import 'package:lotto_runners/utils/web_payment_helper.dart';
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
        // For Web, if "Verify JWT" is ON, we must use the HTML content returned from the POST request
        // because standard URL navigation/launching cannot send the required Authorization headers.
        final htmlContent = intentData['html_content'] as String?;
        
        if (htmlContent != null) {
          setState(() {
            _paymentDataUri = htmlContent; // Store the HTML string
            _isLoading = false;
          });
          // On Web, we open a new tab and write the HTML directly
          _openWebPaymentWindow(htmlContent);
        } else {
          throw Exception('No HTML content received for Web payment');
        }
      } else if (_isWindows) {

        await _initializeWindowsWebView(dataUri);
      } else {
        // Use Mobile WebView controller
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

  Future<void> _launchWebPaymentFromDataUri(String dataUri) async {
    try {
      PayTodayConfig.log('Attempting to launch Web payment...');
      final uri = Uri.parse(dataUri);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        PayTodayConfig.log('Auto-launch blocked, user must click button');
      }
    } catch (e) {
      PayTodayConfig.logError('Auto-launch failed', e);
      // User will need to click the button manually
    }
  }

  Future<void> _openWebPaymentWindow(String htmlContent) async {
    try {
      if (kIsWeb) {
        PayTodayConfig.log('Opening Web payment window via Blob URL...');
        openWebPayment(htmlContent);
      } else {
        PayTodayConfig.log('Opening Web payment via Data URI (Non-Web)...');
        final uri = Uri.dataFromString(
          htmlContent,
          mimeType: 'text/html',
          encoding: utf8,
        );
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) throw Exception('Could not launch payment window.');
      }
    } catch (e) {
      PayTodayConfig.logError('Failed to open payment window', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to launch payment: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _launchWebPayment() async {
    if (_paymentDataUri == null) return;
    
    if (kIsWeb) {
      await _openWebPaymentWindow(_paymentDataUri!);
    } else {
      try {
        PayTodayConfig.log('Launching Web payment from stored data URI');
        final uri = Uri.parse(_paymentDataUri!);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw Exception('Could not launch payment URL. Please check your browser popup blocker.');
        }
      } catch (e) {
        PayTodayConfig.logError('Failed to launch web payment', e);
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to launch payment: ${e.toString()}';
          });
        }
      }
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
      if (url.startsWith('lottorunners://payment-return') || url.contains('payment-return')) {
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
    if (kIsWeb) {
      // On Web, we don't use WebViewController at all - it's handled in _initializePayment
      // This branch shouldn't actually be reached because _initializePayment handles Web separately
      return;
    }

    // Initialize WebView controller for Mobile
    _mobileController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _loadingProgress = progress / 100);
          },
          onPageStarted: (String url) {
            PayTodayConfig.log('Page started: $url');
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            PayTodayConfig.log('Page finished: $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            PayTodayConfig.logError('WebView error', error.description);
            // Don't fail immediately on resource error, might be minor
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('lottorunners://payment-return') || request.url.contains('payment-return')) {
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
    // Parse query parameters
    // PayToday often returns ?status=success or ?status=cancelled
    // Or sometimes ?success=true/false
    final status = uri.queryParameters['status']?.toLowerCase();
    final success = uri.queryParameters['success']?.toLowerCase();
    final transactionId = uri.queryParameters['transaction_id'] ?? uri.queryParameters['id']; 

    PayTodayConfig.log('Return URL params - status: $status, success: $success, txId: $transactionId');

    if (status == 'success' || success == 'true' || status == 'completed') {
      _handlePaymentSuccess(uri);
    } else if (status == 'cancelled' || status == 'canceled' || success == 'false') {
      _handlePaymentCancel(uri);
    } else {
      // Default fallback if logic is unclear but we hit return url
       _handlePaymentSuccess(uri);
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
            _handlePaymentCancel(Uri.parse('lottorunners://payment-return?status=cancelled'));
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

    // Web now uses the standard WebViewWidget (iframe)
    // if (kIsWeb) { ... } block removed to allow fall-through to WebViewWidget

    if (kIsWeb) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              Icon(Icons.payment, size: 64, color: LottoRunnersColors.primaryBlue),
              const SizedBox(height: 24),
              const Text('Payment Window Opened', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
              const Text('Please complete payment in the new tab, then click below.', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              if (_paymentDataUri != null)
              ElevatedButton(
                  onPressed: _launchWebPayment,
                  child: const Text('Re-open Payment Window'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _verifyWebPayment,
                icon: const Icon(Icons.verified),
                label: const Text('I HAVE PAID - CHECK STATUS'),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => _handlePaymentCancel(Uri.parse('lottorunners://payment-return?status=cancelled')),
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
