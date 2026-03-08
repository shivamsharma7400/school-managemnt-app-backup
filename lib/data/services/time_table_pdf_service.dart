import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../core/utils/indic_shaper.dart';

class TimeTablePdfService {
  static pw.Font? _font;
  static pw.Font? _boldFont;
  static pw.MemoryImage? _logo;

  static Future<void> generateBulk({
    required String schoolName,
    required String address,
    required List<Map<String, dynamic>> routines,
  }) async {
    final pdf = pw.Document();

    try {
      _font ??= await PdfGoogleFonts.notoSansDevanagariRegular();
      _boldFont ??= await PdfGoogleFonts.notoSansDevanagariBold();
      
      try {
        final logoData = await rootBundle.load('assets/logos/logo.png');
        _logo = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        print('Logo load error: $e');
      }
    } catch (e) {
      print('Resource loading error: $e');
    }

    final font = _font ?? pw.Font.helvetica();
    final boldFont = _boldFont ?? pw.Font.helveticaBold();

    for (final routine in routines) {
      if (routine['tableData'] == null) continue;
      
      final columns = List<String>.from(routine['tableData']['columns'] ?? []);
      final rawRows = routine['tableData']['rows'] as List? ?? [];
      
      // Convert Map rows to List rows for the PDF service
      final List<List<String>> rows = rawRows.map((row) {
        if (row is Map) {
          final List<String> cells = List.generate(columns.length, (_) => "");
          row.forEach((key, value) {
            final int? index = int.tryParse(key.toString());
            if (index != null && index < cells.length) {
              cells[index] = value.toString();
            }
          });
          return cells;
        } else {
          return List<String>.from(row as List);
        }
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) => pw.Column(
            children: [
              pw.Row(
                children: [
                  if (_logo != null) pw.Container(width: 50, height: 50, child: pw.Image(_logo!)),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _s(schoolName.toUpperCase()), 
                          style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.indigo900)
                        ),
                        pw.Text(
                          _s(address), 
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                    child: pw.Text(
                      _s((routine['title'] ?? 'CLASS ROUTINE').replaceAll('Routine - ', 'Class ')), 
                      style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.white)
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.indigo, thickness: 1),
              pw.SizedBox(height: 10),
            ],
          ),
          build: (pw.Context context) {
            return [
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(80), // DAYS
                  for (int i = 1; i < columns.length; i++)
                    i: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                    children: columns.map((col) => _cell(col, font: boldFont, bold: true, color: PdfColors.indigo900)).toList(),
                  ),
                  ...rows.map((row) {
                    return pw.TableRow(
                      children: row.map((cell) => _cell(cell, font: font)).toList(),
                    );
                  }),
                ],
              ),
            ];
          },
          footer: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bulk_Class_Routines.pdf',
    );
  }

  static Future<void> generate({
    required String schoolName,
    required String address,
    required List<String> columns,
    required List<List<String>> rows,
  }) async {
    final pdf = pw.Document();

    try {
      _font ??= await PdfGoogleFonts.notoSansDevanagariRegular();
      _boldFont ??= await PdfGoogleFonts.notoSansDevanagariBold();
      
      try {
        final logoData = await rootBundle.load('assets/logos/logo.png');
        _logo = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        print('Logo load error: $e');
      }
    } catch (e) {
      print('Resource loading error: $e');
    }

    final font = _font ?? pw.Font.helvetica();
    final boldFont = _boldFont ?? pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              children: [
                if (_logo != null) pw.Container(width: 60, height: 60, child: pw.Image(_logo!)),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _s(schoolName.toUpperCase()), 
                        style: pw.TextStyle(font: boldFont, fontSize: 22, color: PdfColors.indigo900)
                      ),
                      pw.Text(
                        _s(address), 
                        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                        child: pw.Text(
                          'SCHOOL TIME TABLE', 
                          style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.white)
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated on:', 
                      style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)
                    ),
                    pw.Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()), 
                      style: pw.TextStyle(font: boldFont, fontSize: 10)
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.indigo, thickness: 2),
            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(100), // Time Duration
                for (int i = 1; i < columns.length; i++)
                  i: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                  children: columns.map((col) => _cell(col, font: boldFont, bold: true, color: PdfColors.indigo900)).toList(),
                ),
                // Data Rows
                ...rows.map((row) {
                  return pw.TableRow(
                    children: row.map((cell) => _cell(cell, font: font)).toList(),
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 40),
            
            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey400)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Principal Signature', style: pw.TextStyle(font: font, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'School_Time_Table.pdf',
    );
  }

  static pw.Widget _cell(String text, {required pw.Font font, bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: pw.Text(
        _s(text),
        style: pw.TextStyle(
          font: font,
          fontSize: bold ? 11 : 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static String _s(String text) => IndicShaper.shape(text);
}
