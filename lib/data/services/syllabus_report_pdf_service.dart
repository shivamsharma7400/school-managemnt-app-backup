import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../core/utils/indic_shaper.dart';

class SyllabusReportPdfService {
  static pw.Font? _font;
  static pw.Font? _boldFont;
  static pw.MemoryImage? _logo;

  static Future<void> generate({
    required String schoolName,
    required String className,
    required String term,
    required List<String> extraColumns,
    required List<Map<String, dynamic>> syllabusData,
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
                if (_logo != null) pw.Container(width: 50, height: 50, child: pw.Image(_logo!)),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _s(schoolName.toUpperCase()), 
                        style: pw.TextStyle(font: boldFont, fontSize: 20)
                      ),
                      pw.Text(
                        _s('Class Syllabus Report - Class $className'), 
                        style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700)
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            _s('Assessment: $term'), 
                            style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.indigo)
                          ),
                          pw.Text(
                            _s('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'), 
                            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Subject
                1: const pw.FlexColumnWidth(3), // Teacher
                2: const pw.FlexColumnWidth(3), // Target Chapter
                for (int i = 0; i < extraColumns.length; i++)
                  i + 3: const pw.FlexColumnWidth(2), // Extra columns
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _cell('SUB', font: boldFont, bold: true),
                    _cell('Teacher', font: boldFont, bold: true),
                    _cell('Target Chapter', font: boldFont, bold: true),
                    ...extraColumns.map((col) => _cell(col, font: boldFont, bold: true)),
                  ],
                ),
                // Data Rows
                ...syllabusData.map((item) {
                  final chapters = item['chapters'] as List?;
                  final termChapters = chapters
                      ?.where((c) => c['term'] == term)
                      .map((c) => c['no'].toString())
                      .toList() ?? [];
                  
                  final targetChapter = termChapters.isNotEmpty 
                      ? 'Ch. ${termChapters.join(', ')}' 
                      : '';

                  return pw.TableRow(
                    children: [
                      _cell(item['subjectName'] ?? '', font: font),
                      _cell(item['teacherName'] ?? '', font: font), // Blank if null
                      _cell(targetChapter, font: font),
                      ...List.generate(extraColumns.length, (_) => _cell('', font: font)),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 40),
            
            // Footer (Signatures)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(width: 0.5)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Class Teacher', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(width: 0.5)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Principal', style: pw.TextStyle(font: font, fontSize: 10)),
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
      name: '${className.replaceAll(' ', '_')}_Syllabus_Report.pdf',
    );
  }

  static pw.Widget _cell(String text, {required pw.Font font, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(
        _s(text),
        style: pw.TextStyle(
          font: font,
          fontSize: bold ? 10 : 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _s(String text) => IndicShaper.shape(text);
}
