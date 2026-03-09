import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../models/scheduled_exam_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/drive_helper.dart';

class StudentExamPdfService {
  static Future<void> printExamRoutine(
    ScheduledExam exam,
    Map<String, dynamic>? routineConfig, 
    Map<String, dynamic>? routineAssignments,
  ) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load('assets/logos/logo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      print('Logo not found: $e');
    }

    final safeConfig = routineConfig ?? {};
    final startTime = safeConfig['startTime'] ?? '09:30 AM';
    final endTime = safeConfig['endTime'] ?? '12:30 PM';
    final duration = safeConfig['duration'] ?? '3 Hours';
    
    // Prepare table data from assignments
    final List<List<String>> tableData = [];
    if (routineAssignments != null) {
      final sortedDates = routineAssignments.keys.toList()..sort();
      for (var dateStr in sortedDates) {
        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        final day = DateFormat('EEEE').format(date);
        final List<dynamic> subjects = routineAssignments[dateStr] ?? [];
        
        final assignedSubjects = subjects
            .where((s) => s != null)
            .map((s) => s.toString())
            .join(', ');
        
        if (assignedSubjects.isNotEmpty) {
           tableData.add([
            DateFormat('dd/MM/yyyy').format(date),
            day,
            '$startTime - $endTime',
            assignedSubjects.toUpperCase(),
          ]);
        }
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
               pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                   if (logoImage != null)
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(logoImage),
                    ),
                  pw.SizedBox(width: 25),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(AppStrings.appName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 26, color: PdfColors.red800)),
                      pw.Text(AppStrings.schoolAddress, style: pw.TextStyle(font: font, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 10),
              pw.Text('Exam Routine - ${exam.name}', style: pw.TextStyle(font: fontBold, fontSize: 20, decoration: pw.TextDecoration.underline)),
              pw.SizedBox(height: 10),
              pw.Text('Duration: $duration', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              
              // Routine Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Date', fontBold, isHeader: true),
                      _buildTableCell('Day', fontBold, isHeader: true),
                      _buildTableCell('Timing', fontBold, isHeader: true),
                      _buildTableCell('Subject', fontBold, isHeader: true),
                    ],
                  ),
                  if (tableData.isEmpty)
                    pw.TableRow(
                      children: [
                        _buildTableCell('N/A', font),
                        _buildTableCell('N/A', font),
                        _buildTableCell('N/A', font),
                        _buildTableCell('No Routine Found', font),
                      ],
                    ),
                  ...tableData.map((row) => pw.TableRow(
                    children: row.map((cell) => _buildTableCell(cell, font)).toList(),
                  )),
                ],
              ),
              
              pw.SizedBox(height: 30),
              pw.Text('Note: Students are expected to arrive at least 15 minutes before the exam starts.', 
                style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.red900)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  static Future<void> printAdmitCard(
    ScheduledExam exam, 
    Map<String, dynamic> student, 
    Map<String, dynamic>? routineConfig, 
    Map<String, dynamic>? routineAssignments
  ) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();
    
    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load('assets/logos/logo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      print('Logo not found: $e');
    }

    // Load student photo
    pw.MemoryImage? studentPhoto;
    String photoUrlToUse = DriveHelper.getDirectDriveUrl(student['photoUrl']?.toString() ?? '') ?? '';

    if (photoUrlToUse.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(photoUrlToUse)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          studentPhoto = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading student photo: $e');
      }
    }

  final classSecStr = (() {
    String classStr = student['className']?.toString() ?? 'N/A';
    String sec = (student['customData'] as Map?)?['Sec']?.toString() ?? '';
    return (sec.isNotEmpty && !classStr.contains('-')) ? '$classStr-$sec' : classStr;
  })();

  final rollNoStr = (student['customData'] as Map?)?['Roll.no']?.toString() ?? '-';

  final List<List<String>> tableData = [];
    if (routineAssignments != null) {
      final sortedDates = routineAssignments.keys.toList()..sort();
      for (var dateStr in sortedDates) {
        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        final day = DateFormat('EEEE').format(date);
        final List<dynamic> subjects = routineAssignments[dateStr] ?? [];
        
        final assignedSubjects = subjects
            .where((s) => s != null)
            .map((s) => s.toString())
            .join(', ');
        
        if (assignedSubjects.isNotEmpty) {
           tableData.add([
            DateFormat('dd/MM/yyyy').format(date),
            day,
            '${routineConfig?['startTime'] ?? '09:30 AM'} - ${routineConfig?['endTime'] ?? '12:30 PM'}',
            assignedSubjects.toUpperCase(),
            '', 
          ]);
        }
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                   if (logoImage != null)
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(logoImage),
                    ),
                  pw.SizedBox(width: 25),
                  pw.Column(
                    children: [
                      pw.Text(AppStrings.appName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 26, color: PdfColors.red800)),
                       pw.Text(AppStrings.schoolAddress, style: pw.TextStyle(font: font, fontSize: 11)),
                      pw.Text('Phone: ${AppStrings.schoolPhone} | E-mail: ${AppStrings.schoolEmail}', style: pw.TextStyle(font: font, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('Admit Card - ${exam.name} 2025-2026', 
                  style: pw.TextStyle(font: fontBold, fontSize: 18, decoration: pw.TextDecoration.underline)),
              ),
              pw.SizedBox(height: 25),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfDetailRow('Adm No. :', student['admNo']?.toString() ?? 'N/A', font, fontBold),
                        _buildPdfDetailRow('Name:', student['name']?.toUpperCase() ?? 'N/A', font, fontBold, valueColor: PdfColors.blue800),
                        _buildPdfDetailRow('Father\'s Name :', student['fatherName']?.toUpperCase() ?? 'N/A', font, fontBold, valueColor: PdfColors.blue800),
                        pw.Row(
                          children: [
                            pw.Expanded(child: _buildPdfDetailRow('Roll No. :', rollNoStr, font, fontBold)),
                            pw.Expanded(child: _buildPdfDetailRow('Class/Sec :', classSecStr, font, fontBold, valueColor: PdfColors.red800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 100,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 1.5),
                    ),
                    child: studentPhoto != null 
                        ? pw.Image(studentPhoto, fit: pw.BoxFit.cover)
                        : pw.Center(child: pw.Text('Photo', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey))),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Center(child: pw.Text('Exam Schedule', style: pw.TextStyle(font: fontBold, fontSize: 15, decoration: pw.TextDecoration.underline))),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(4.5),
                  3: const pw.FlexColumnWidth(7),
                  4: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Date', fontBold, isHeader: true),
                      _buildTableCell('Day', fontBold, isHeader: true),
                      _buildTableCell('Timing', fontBold, isHeader: true),
                      _buildTableCell('Subject', fontBold, isHeader: true),
                      _buildTableCell('Invigilator\'s Signature', fontBold, isHeader: true),
                    ],
                  ),
                  if (tableData.isEmpty)
                    pw.TableRow(
                      children: [
                        _buildTableCell('N/A', font),
                        _buildTableCell('N/A', font),
                        _buildTableCell('N/A', font),
                        _buildTableCell('No Routine Found', font),
                        _buildTableCell('N/A', font),
                      ],
                    ),
                  ...tableData.map((row) => pw.TableRow(
                    children: row.map((cell) => _buildTableCell(cell, font)).toList(),
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Note: It is compulsory to carry Admit card to school on all examination days.', 
                style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.red900)),
              pw.SizedBox(height: 40),
              pw.Center(child: pw.Text('WISH YOU ALL THE BEST!!!', style: pw.TextStyle(font: fontBold, fontSize: 16, letterSpacing: 1))),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 8),
                      pw.Text('Class Teacher Signature', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 8),
                      pw.Text('Principal Signature', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  static pw.Widget _buildPdfDetailRow(String label, String value, pw.Font font, pw.Font fontBold, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 12, color: valueColor ?? PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: isHeader ? 10 : 9),
      ),
    );
  }

  static Future<void> printMarkSheet(
    ScheduledExam exam,
    Map<String, dynamic> student,
    Map<String, dynamic> studentMarks,
    List<Map<String, dynamic>> previewSubjects,
  ) async {
    double totalObtained = 0;
    double maxMarks = 0;
    for (var sub in previewSubjects) {
      final name = sub['name'];
      totalObtained += double.tryParse(studentMarks[name]?.toString() ?? '0') ?? 0;
      maxMarks += (sub['fullMarks'] as num?)?.toDouble() ?? 100.0;
    }

    double percentage = maxMarks > 0 ? (totalObtained / maxMarks * 100) : 0;
    String grade = _calculateGrade(percentage);

    final doc = pw.Document();
    final font = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    // Load school logo
    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load('assets/logos/logo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      print('Logo not found: $e');
    }

    // Load student photo
    pw.MemoryImage? studentPhoto;
    String photoUrlToUse = DriveHelper.getDirectDriveUrl(student['photoUrl']?.toString() ?? '') ?? '';

    if (photoUrlToUse.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(photoUrlToUse)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          studentPhoto = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading student photo: $e');
      }
    }

    final classSecStr = (() {
      String classStr = student['className']?.toString() ?? 'N/A';
      String sec = (student['customData'] as Map?)?['Sec']?.toString() ?? '';
      return (sec.isNotEmpty && !classStr.contains('-')) ? '$classStr-$sec' : classStr;
    })();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 70,
                    height: 70,
                    child: pw.Image(logoImage),
                  ),
                pw.SizedBox(width: 15),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(AppStrings.appName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.red800)),
                    pw.Text(AppStrings.schoolAddress, style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('Phone: ${AppStrings.schoolPhone} | E-mail: ${AppStrings.schoolEmail}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('EXAM MARK SHEET', 
                  style: pw.TextStyle(font: fontBold, fontSize: 16, decoration: pw.TextDecoration.underline)),
              ),
              pw.SizedBox(height: 20),
              
              // Student Details + Photo
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfDetailLine('Student Name :', student['name']?.toUpperCase() ?? 'N/A', font, fontBold),
                        _buildPdfDetailLine('Adm. No :', student['admNo']?.toString() ?? 'N/A', font, fontBold),
                        _buildPdfDetailLine('Father\'s Name :', (student['fatherName'] ?? 'N/A').toUpperCase(), font, fontBold),
                        _buildPdfDetailLine('Examination :', exam.name, font, fontBold),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfDetailLine('Class/Sec :', classSecStr, font, fontBold),
                        _buildPdfDetailLine('Roll No. :', (student['customData'] as Map?)?['Roll.no']?.toString() ?? 'N/A', font, fontBold),
                      ],
                    ),
                  ),
                  // Photo Box repositioned here
                  pw.Container(
                    width: 80,
                    height: 90,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: studentPhoto != null 
                        ? pw.Image(studentPhoto, fit: pw.BoxFit.cover)
                        : pw.Center(
                            child: pw.Text('PHOTO', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey400)),
                          ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Marks Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell('SUBJECT', fontBold, isHeader: true),
                      _buildTableCell('MAX MARKS', fontBold, isHeader: true),
                      _buildTableCell('OBTAINED', fontBold, isHeader: true),
                    ],
                  ),
                  ...previewSubjects.map((sub) => pw.TableRow(
                    children: [
                      _buildTableCell(sub['name'].toString().toUpperCase(), font),
                      _buildTableCell(sub['fullMarks'].toString(), font),
                      _buildTableCell(studentMarks[sub['name']]?.toString() ?? '0', fontBold),
                    ],
                  )),
                ],
              ),
              
              pw.SizedBox(height: 25),
              // Footer Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  color: PdfColors.grey50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfSummaryItem('TOTAL', '${totalObtained.toStringAsFixed(0)} / ${maxMarks.toStringAsFixed(0)}', font, fontBold),
                    _buildPdfSummaryItem('PERCENTAGE', '${percentage.toStringAsFixed(1)}%', font, fontBold),
                    _buildPdfSummaryItem('GRADE', grade, font, fontBold),
                  ],
                ),
              ),
              
              pw.Spacer(),
              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('Class Teacher Signature', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('Principal Signature', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Issued by Veena Public School Management System', 
                  style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  static pw.Widget _buildPdfDetailLine(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfSummaryItem(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900)),
      ],
    );
  }

  static String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    if (percentage >= 33) return 'P';
    return 'F';
  }
}
