import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class SalaryPdfService {
  static Future<void> generateReceiptPdf({
    required Map<String, dynamic> schoolInfo,
    required Map<String, dynamic> staffData,
    required Map<String, dynamic> transaction,
    List<Map<String, dynamic>>? history,
  }) async {
    final pdf = pw.Document();
    
    // Formatting Dates
    final date = (transaction['date'] != null) 
      ? (transaction['date'] is DateTime ? transaction['date'] : transaction['date'].toDate()) 
      : DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(date);

    // Data Calculation for Clearance
    final monthlySalary = (staffData['monthlySalary'] as num?)?.toDouble() ?? 0.0;
    final closingBalance = (transaction['balanceAfter'] as num?)?.toDouble() ?? (staffData['salaryDue'] as num?)?.toDouble() ?? 0.0;
    final paymentAmount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final openingBalance = closingBalance + paymentAmount;
    final selectedMonth = transaction['month'] ?? DateFormat('MMMM yyyy').format(date);

    // Load logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/logos/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print("Could not load logo: $e");
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Corporate Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   if (logoImage != null)
                    pw.Image(logoImage, width: 70, height: 70)
                  else
                    pw.SizedBox(width: 70, height: 70),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(schoolInfo['schoolName']?.toUpperCase() ?? 'YOUR SCHOOL NAME',
                            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                        pw.SizedBox(height: 4),
                        pw.Text(schoolInfo['address'] ?? 'School Address',
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text("Contact: ${schoolInfo['phone'] ?? ''} | Email: ${schoolInfo['email'] ?? ''}",
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(color: PdfColors.indigo900),
                        child: pw.Text("PAYMENT VOUCHER", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text("Voucher No: ${transaction['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 25),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 20),

              // 2. Employee Info Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _field("Employee Name", staffData['name'] ?? 'N/A'),
                      _field("Staff ID", staffData['staffId'] ?? staffData['teacherId'] ?? 'N/A'),
                      _field("Designation", staffData['role']?.toString().toUpperCase() ?? 'Staff'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _field("Statement Date", dateStr),
                      _field("Payment For Month", selectedMonth, isBold: true),
                      _field("Payment Mode", transaction['method'] ?? 'Cash'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // 3. Financial Clearance Summary
              pw.Text("ACCOUNT CLEARANCE SUMMARY", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _cell("Description", isHeader: true),
                      _cell("Amount (INR)", isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cell("Opening Balance Due (Before this payment)"),
                      _cell("Rs. ${openingBalance.toStringAsFixed(2)}", align: pw.TextAlign.right),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cell("Current Payment Made ($selectedMonth)"),
                      _cell("(-) Rs. ${paymentAmount.toStringAsFixed(2)}", align: pw.TextAlign.right, color: PdfColors.green700),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.indigo50),
                    children: [
                      _cell("FINAL BALANCE DUE (Total Clearance)", isBold: true),
                      _cell("Rs. ${closingBalance.toStringAsFixed(2)}", isBold: true, align: pw.TextAlign.right, color: PdfColors.red700),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // 5. Signature Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 0.5, color: PdfColors.grey700),
                      pw.SizedBox(height: 5),
                      pw.Text("Employee Signature", style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 0.5, color: PdfColors.grey700),
                      pw.SizedBox(height: 5),
                      pw.Text("Authorized Signatory", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Center(
                child: pw.Text("This is an official document generated by the $selectedMonth payroll system.", 
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _field(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(width: 110, child: pw.Text("$label:", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false, bool isBold = false, pw.TextAlign align = pw.TextAlign.left, double fontSize = 10, PdfColor? color}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }
}
