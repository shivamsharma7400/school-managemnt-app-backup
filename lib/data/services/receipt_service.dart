import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateAndShowReceipt(BuildContext context, Map<String, dynamic> transaction) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing your receipt...'), duration: Duration(seconds: 1)),
      );

      final pdf = await _createPdf(transaction);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_${transaction['id'] ?? 'N/A'}.pdf',
      );
    } catch (e) {
      print('Receipt Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open receipt: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<pw.Document> _createPdf(Map<String, dynamic> transaction) async {
    final pdf = pw.Document();

    // 1. Fetch User Data
    final userDoc = await _firestore.collection('users').doc(transaction['userId']).get();
    final userData = userDoc.data() ?? {};
    final feeConfig = userData['feeConfig'] as Map<String, dynamic>? ?? {};

    // 2. Fetch School Info
    final schoolInfoDoc = await _firestore.collection('school_settings').doc('info').get();
    final schoolInfo = schoolInfoDoc.data() ?? {};

    // 3. Fetch Config (for Logo)
    final configDoc = await _firestore.collection('settings').doc('config').get();
    final configData = configDoc.data() ?? {};

    // 4. Fetch Class Data for Fee Structure
    final classId = userData['classId']?.toString() ?? '';
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    final classData = classDoc.data() ?? {};

    final String schoolName = configData['schoolName'] ?? schoolInfo['name'] ?? 'VEENA PUBLIC SCHOOL';
    final String schoolAddress = schoolInfo['address'] ?? 'KHIDDI, RAJOUN, BANKA (BIHAR) -813107';
    final String schoolContact = schoolInfo['contact'] ?? '+91- 9263101520';
    final String logoUrl = configData['schoolLogoUrl'] ?? '';

    // Load Logo if available
    pw.ImageProvider? logoImage;
    if (logoUrl.isNotEmpty) {
      try {
        logoImage = await networkImage(logoUrl).timeout(const Duration(seconds: 5));
      } catch (e) {
        print('Error loading network logo: $e');
      }
    }

    // Fallback to local asset if network logo failed or URL was empty
    if (logoImage == null) {
      try {
        final ByteData bytes = await rootBundle.load('assets/logos/logo.png');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {
        print('Error loading asset logo: $e');
      }
    }

    final date = (transaction['date'] as dynamic)?.toDate() ?? DateTime.now();
    final amountPaid = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final String receiptNo = transaction['receiptNo'] ?? 'REC-${(transaction['id'] ?? '0000').toString().length > 8 ? transaction['id'].toString().substring(0, 8).toUpperCase() : transaction['id'].toString().toUpperCase()}';

    // Load fonts that support the Rupee symbol
    final pw.Font rupeeFontRegular = await PdfGoogleFonts.notoSansRegular();
    final pw.Font rupeeFontBold = await PdfGoogleFonts.notoSansBold();

    final primaryColor = PdfColor.fromInt(0xFF3F51B5); // Indigo
    final secondaryColor = PdfColors.grey800;

    // --- Dynamic Fee Calculations ---
    final double monthlyFee = (classData['monthlyFee'] ?? 0.0).toDouble();
    final double coachingFeeBase = (classData['coachingFee'] ?? 0.0).toDouble();
    final double milkFeeBase = (classData['milkFee'] ?? 0.0).toDouble();
    final double busFeeBase = (classData['busFee'] ?? 0.0).toDouble();
    final double hostelFeeBase = (classData['hostelFee'] ?? 0.0).toDouble();

    List<pw.TableRow> feeRows = [];
    double currentMonthTotal = 0.0;

    // Helper to add rows
    pw.TableRow _row(String label, dynamic rate, dynamic amount) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8), 
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8), 
            child: pw.Text('₹${rate.toString()}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8), 
            child: pw.Text('₹${amount.toString()}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))
          ),
        ],
      );
    }

    // Optional Components
    if (feeConfig['Coaching Fee'] != false && coachingFeeBase > 0) {
      feeRows.add(_row('Coaching Fee', coachingFeeBase.toInt(), coachingFeeBase.toInt()));
      currentMonthTotal += coachingFeeBase;
    }
    if (feeConfig['Milk Fee'] != false && milkFeeBase > 0) {
      feeRows.add(_row('Milk Fee', milkFeeBase.toInt(), milkFeeBase.toInt()));
      currentMonthTotal += milkFeeBase;
    }
    if (feeConfig['Bus Fee'] != false && busFeeBase > 0) {
      feeRows.add(_row('Bus Fee', busFeeBase.toInt(), busFeeBase.toInt()));
      currentMonthTotal += busFeeBase;
    }
    if (feeConfig['Hostel Fee'] != false && hostelFeeBase > 0) {
      feeRows.add(_row('Hostel Fee', hostelFeeBase.toInt(), hostelFeeBase.toInt()));
      currentMonthTotal += hostelFeeBase;
    }

    // Financial calculations
    final double currentDueAfterPayment = (userData['currentDue'] as num?)?.toDouble() ?? 0.0;
    final double totalPayablePrior = currentDueAfterPayment + amountPaid;
    final double previousDue = totalPayablePrior - currentMonthTotal;

    if (previousDue > 0) {
      feeRows.add(_row('Previous Due Balance', previousDue.toInt(), previousDue.toInt()));
    } else if (previousDue < 0) {
       // Advanced Payment or discount
       feeRows.add(_row('Adjustments / Bonus', previousDue.toInt(), previousDue.toInt()));
    }

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: rupeeFontRegular,
          bold: rupeeFontBold,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 1),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header section (Centered)
                pw.Center(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 70, 
                          height: 70, 
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Image(logoImage),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey100, width: 0.5),
                          ),
                        ),
                      pw.Text(schoolName.toUpperCase(),
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(schoolAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('Contact: $schoolContact', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: primaryColor, thickness: 1.5),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: pw.Text('OFFICIAL FEE RECEIPT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                ),
                pw.SizedBox(height: 24),

                // Student info Grid
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        children: [
                          _buildModernInfoRow('Student Name', userData['name']?.toString()?.toUpperCase() ?? 'N/A'),
                          _buildModernInfoRow('Father\'s Name', userData['fatherName']?.toString()?.toUpperCase() ?? 'N/A'),
                          _buildModernInfoRow('Admission No.', userData['admNo']?.toString() ?? 'N/A'),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        children: [
                          _buildModernInfoRow('Receipt Number', receiptNo),
                          _buildModernInfoRow('Payment Date', DateFormat('dd MMM, yyyy').format(date)),
                          _buildModernInfoRow('Class / Roll', '${userData['classId']?.toString()?.toUpperCase() ?? 'N/A'} - Roll: ${userData['rollNo']?.toString() ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 32),

                // Table section
                pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    bottom: pw.BorderSide(color: primaryColor, width: 1),
                  ),
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: primaryColor),
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
                          child: pw.Text('Charges Info', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11))
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
                          child: pw.Text('Charge', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11))
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
                          child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11))
                        ),
                      ],
                    ),
                    // Table Content
                    ...feeRows,
                  ],
                ),

                // Summary section
                 pw.Container(
                  padding: const pw.EdgeInsets.only(top: 16),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 250,
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey50,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Column(
                          children: [
                            _buildModernSummaryRow('Total Owed', '₹${totalPayablePrior.toStringAsFixed(2)}', isBold: true),
                            _buildModernSummaryRow('Amount Paid', '₹${amountPaid.toStringAsFixed(2)}', isBold: true, color: PdfColors.green800),
                            pw.Divider(color: PdfColors.grey300),
                            _buildModernSummaryRow(
                              currentDueAfterPayment > 0 ? 'Status: DUE' : 'Status: PAID', 
                              '₹${currentDueAfterPayment.toStringAsFixed(2)}', 
                              isBold: true, 
                              color: currentDueAfterPayment > 0 ? PdfColors.red800 : PdfColors.green800
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 32),
                
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                       pw.Text('AMOUNT IN WORDS:', style: pw.TextStyle(fontSize: 9, color: secondaryColor, fontWeight: pw.FontWeight.bold)),
                       pw.SizedBox(height: 4),
                       pw.Text('${amountToWords(amountPaid)} ONLY', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),
                pw.Text('Remarks: ${transaction['remarks'] ?? 'Payment processed successfully.'}', style: pw.TextStyle(fontSize: 10, color: secondaryColor)),
                pw.Text('Mode of Payment: ${transaction['paymentMethod'] ?? 'Cash'}', style: pw.TextStyle(fontSize: 10, color: secondaryColor)),
                
                pw.Spacer(),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(height: 1, width: 150, color: PdfColors.grey400),
                        pw.SizedBox(height: 4),
                        pw.Text('Depositor\'s Signature', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('For, $schoolName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 30),
                        pw.Container(height: 1, width: 150, color: PdfColors.grey400),
                        pw.SizedBox(height: 4),
                        pw.Text('Authorized Seal & Signature', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text('This is a computer-generated receipt.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildModernInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  pw.Widget _buildModernSummaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black)),
        ],
      ),
    );
  }

  String amountToWords(double amount) {
    if (amount == 0) return "ZERO";
    
    final units = ["", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN"];
    final tens = ["", "", "TWENTY", "THIRTY", "FORTY", "FIFTY", "SIXTY", "SEVENTY", "EIGHTY", "NINETY"];
    
    String convert(int n) {
      if (n < 20) return units[n];
      if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? " " + units[n % 10] : "");
      if (n < 1000) return units[n ~/ 100] + " HUNDRED" + (n % 100 != 0 ? " AND " + convert(n % 100) : "");
      return "";
    }

    int value = amount.toInt();
    if (value < 1000) return convert(value);
    
    if (value < 100000) {
      return convert(value ~/ 1000) + " THOUSAND" + (value % 1000 != 0 ? " " + convert(value % 1000) : "");
    }

    if (value < 10000000) {
      return convert(value ~/ 100000) + " LAKH" + (value % 100000 != 0 ? " " + convert(value % 100000) : "");
    }
    
    return value.toString();
  }
}
