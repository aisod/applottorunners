import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

/// Invoice Service
/// 
/// Generates professional invoices for business users when they create
/// errands or bookings. Invoices include company details, itemized costs,
/// and payment information.
class InvoiceService {
  /// Generate and display invoice for an errand
  static Future<void> generateErrandInvoice({
    required String errandId,
    required String title,
    required double amount,
    required Map<String, dynamic> userProfile,
  }) async {
    try {
      print('📄 Generating invoice for errand: $errandId');

      final pdf = pw.Document();
      final now = DateTime.now();
      final invoiceNumber = 'INV-ERR-${DateTime.now().millisecondsSinceEpoch}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildInvoiceContent(
              invoiceNumber: invoiceNumber,
              date: now,
              customerName: userProfile['full_name'] ?? 'Business Customer',
              customerEmail: userProfile['email'] ?? '',
              customerPhone: userProfile['phone'] ?? '',
              companyName: userProfile['company_name'] ?? userProfile['full_name'] ?? 'Company',
              items: [
                InvoiceItem(
                  description: title,
                  quantity: 1,
                  unitPrice: amount,
                  total: amount,
                ),
              ],
              subtotal: amount,
              tax: 0, // Add tax calculation if needed
              total: amount,
              serviceType: 'Errand Service',
            );
          },
        ),
      );

      // Display the invoice
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      print('✅ Invoice generated successfully');
    } catch (e) {
      print('❌ Error generating invoice: $e');
      rethrow;
    }
  }

  /// Generate and display invoice for a transportation booking
  static Future<void> generateTransportationInvoice({
    required String bookingId,
    required String pickupLocation,
    required String dropoffLocation,
    required double amount,
    required Map<String, dynamic> userProfile,
    String? vehicleType,
    int? passengerCount,
  }) async {
    try {
      print('📄 Generating invoice for transportation booking: $bookingId');

      final pdf = pw.Document();
      final now = DateTime.now();
      final invoiceNumber = 'INV-TRANS-${DateTime.now().millisecondsSinceEpoch}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildInvoiceContent(
              invoiceNumber: invoiceNumber,
              date: now,
              customerName: userProfile['full_name'] ?? 'Business Customer',
              customerEmail: userProfile['email'] ?? '',
              customerPhone: userProfile['phone'] ?? '',
              companyName: userProfile['company_name'] ?? userProfile['full_name'] ?? 'Company',
              items: [
                InvoiceItem(
                  description: 'Transportation Service\n$pickupLocation → $dropoffLocation',
                  quantity: passengerCount ?? 1,
                  unitPrice: amount / (passengerCount ?? 1),
                  total: amount,
                  details: vehicleType != null ? 'Vehicle: $vehicleType' : null,
                ),
              ],
              subtotal: amount,
              tax: 0,
              total: amount,
              serviceType: 'Transportation Service',
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      print('✅ Invoice generated successfully');
    } catch (e) {
      print('❌ Error generating invoice: $e');
      rethrow;
    }
  }

  /// Generate and display invoice for a contract booking
  static Future<void> generateContractInvoice({
    required String contractId,
    required String description,
    required double amount,
    required Map<String, dynamic> userProfile,
    String? durationType,
    int? durationValue,
  }) async {
    try {
      print('📄 Generating invoice for contract: $contractId');

      final pdf = pw.Document();
      final now = DateTime.now();
      final invoiceNumber = 'INV-CONTRACT-${DateTime.now().millisecondsSinceEpoch}';

      final durationText = durationType != null && durationValue != null
          ? '$durationValue $durationType'
          : '';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildInvoiceContent(
              invoiceNumber: invoiceNumber,
              date: now,
              customerName: userProfile['full_name'] ?? 'Business Customer',
              customerEmail: userProfile['email'] ?? '',
              customerPhone: userProfile['phone'] ?? '',
              companyName: userProfile['company_name'] ?? userProfile['full_name'] ?? 'Company',
              items: [
                InvoiceItem(
                  description: 'Contract Service\n$description',
                  quantity: 1,
                  unitPrice: amount,
                  total: amount,
                  details: durationText.isNotEmpty ? 'Duration: $durationText' : null,
                ),
              ],
              subtotal: amount,
              tax: 0,
              total: amount,
              serviceType: 'Contract Service',
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      print('✅ Invoice generated successfully');
    } catch (e) {
      print('❌ Error generating invoice: $e');
      rethrow;
    }
  }

  /// Build the invoice PDF content
  static pw.Widget _buildInvoiceContent({
    required String invoiceNumber,
    required DateTime date,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String companyName,
    required List<InvoiceItem> items,
    required double subtotal,
    required double tax,
    required double total,
    required String serviceType,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LOTTO RUNNERS',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Professional Service Platform',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    invoiceNumber,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 40),

          // Customer Information
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BILL TO:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    customerName,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  if (customerEmail.isNotEmpty)
                    pw.Text(
                      customerEmail,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  if (customerPhone.isNotEmpty)
                    pw.Text(
                      customerPhone,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'DATE:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    dateFormat.format(date),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'SERVICE TYPE:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    serviceType,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 40),

          // Items Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                ),
                children: [
                  _buildTableCell('DESCRIPTION', isHeader: true),
                  _buildTableCell('QTY', isHeader: true, align: pw.TextAlign.center),
                  _buildTableCell('UNIT PRICE', isHeader: true, align: pw.TextAlign.right),
                  _buildTableCell('TOTAL', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Items
              ...items.map((item) => pw.TableRow(
                    children: [
                      _buildTableCell(
                        item.details != null
                            ? '${item.description}\n${item.details}'
                            : item.description,
                      ),
                      _buildTableCell(
                        '${item.quantity}',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        'N\$${item.unitPrice.toStringAsFixed(2)}',
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        'N\$${item.total.toStringAsFixed(2)}',
                        align: pw.TextAlign.right,
                      ),
                    ],
                  )),
            ],
          ),

          pw.SizedBox(height: 20),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 300,
                child: pw.Column(
                  children: [
                    _buildTotalRow('Subtotal:', subtotal),
                    if (tax > 0) _buildTotalRow('Tax:', tax),
                    pw.Divider(thickness: 2),
                    _buildTotalRow(
                      'TOTAL:',
                      total,
                      isBold: true,
                      isLarge: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.Spacer(),

          // Footer
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Payment Information',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Payment will be processed through the Lotto Runners platform.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'For inquiries, contact: support@lottorunners.com',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isLarge ? 16 : 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'N\$${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: isLarge ? 16 : 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Invoice item data class
class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? details;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.details,
  });
}

