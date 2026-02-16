import 'dart:html' as html;

void openWebPayment(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Optional: Revoke URL after some time to clean up memory
}
