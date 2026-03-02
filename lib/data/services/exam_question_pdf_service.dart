import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/exam_question_model.dart';
import 'package:intl/intl.dart';
import '../../core/utils/indic_shaper.dart';

class ExamQuestionPdfService {
  static pw.Font? _font;
  static pw.Font? _boldFont;
  static pw.MemoryImage? _logo;

  static Future<String?> generateAndPrint(ExamQuestionPaper paper) async {
    try {
      final pdf = pw.Document();

      // Load fonts
      try {
        _font ??= await PdfGoogleFonts.notoSansDevanagariRegular();
        _boldFont ??= await PdfGoogleFonts.notoSansDevanagariBold();
        
        // Load Logo
        if (_logo == null) {
          try {
            final logoData = await rootBundle.load('assets/logos/logo.png');
            _logo = pw.MemoryImage(logoData.buffer.asUint8List());
          } catch (e) {
            print('Logo load error: $e');
          }
        }
      } catch (fontError) {
        return "Font Loading Error: Please check your internet connection.";
      }
      
      final font = _font!;
      final boldFont = _boldFont!;

      // --- Aggressive Adaptive Scaling Logic ---
      int totalItems = 0;
      final List<QuestionSection> sectionsList = paper.sections.toList();
      for (int sIndex = 0; sIndex < sectionsList.length; sIndex++) {
        final QuestionSection s = sectionsList[sIndex];
        totalItems += 2; // Section header + padding
        final List<QuestionItem> itemsList = s.items.toList();
        for (int iIndex = 0; iIndex < itemsList.length; iIndex++) {
          final QuestionItem i = itemsList[iIndex];
          totalItems += 1; // Question
          totalItems += i.subQuestions.length; // Sub-questions
        }
      }

      // Base sizes (Modern & Professional)
      double baseFontSize = 11.5;
      double headerFontSize = 22;
      double examNameSize = 13.5;
      double spacing = 8;
      double subSpacing = 7;
      double margin = 28;

      // Scaling brackets
      if (totalItems > 30) {
        baseFontSize = 10.5;
        examNameSize = 12.5;
        spacing = 6;
        subSpacing = 5;
      }
      if (totalItems > 50) {
        baseFontSize = 9.5;
        examNameSize = 11.5;
        spacing = 5;
        subSpacing = 4;
        margin = 24;
      }
      if (totalItems > 75) {
        baseFontSize = 8.5;
        spacing = 4;
        subSpacing = 3;
        margin = 20;
      }
      if (totalItems > 100) {
        baseFontSize = 7.5; // Very aggressive for huge papers
        spacing = 3;
        subSpacing = 2;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(margin, 12, margin, margin),
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];

            // 1. School Header (Logo, Name, Branches)
            widgets.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                   if (_logo != null)
                    pw.Container(
                      width: 70,
                      height: 70,
                      margin: const pw.EdgeInsets.only(right: 15),
                      child: pw.Image(_logo!),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          _s(paper.schoolName.toUpperCase()),
                          style: pw.TextStyle(font: boldFont, fontSize: headerFontSize),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          _s(paper.address),
                          style: pw.TextStyle(font: boldFont, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (_logo != null) pw.SizedBox(width: 70), // Balance the logo on the left
                ],
              ),
            );

            widgets.add(pw.SizedBox(height: 5));

            // 2. Metadata Metadata Row
            widgets.add(
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 1.2),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Column(
                  children: [
                    // Row 1: Class | Exam Name (centered) | F.M.
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.SizedBox(
                          width: 150,
                          child: pw.Text(_s('Class: ${paper.className}'), style: pw.TextStyle(font: boldFont, fontSize: baseFontSize)),
                        ),
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(width: 1.2)),
                            ),
                            child: pw.Text(
                              _s('${paper.examName.toUpperCase()}: ${paper.session}'),
                              style: pw.TextStyle(font: boldFont, fontSize: examNameSize),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                        pw.SizedBox(
                          width: 150,
                          child: pw.Text(_s('F.M.: ${paper.fullMarks}'), style: pw.TextStyle(font: boldFont, fontSize: baseFontSize), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    // Row 2: Date | Subject (centered) | Time
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.SizedBox(
                          width: 150,
                          child: pw.Text(_s('Date: ${DateFormat('dd.MM.yy').format(paper.date)}'), style: pw.TextStyle(font: boldFont, fontSize: baseFontSize)),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            _s(paper.subject.toUpperCase()),
                            style: pw.TextStyle(font: boldFont, fontSize: baseFontSize + 2),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.SizedBox(
                          width: 150,
                          child: pw.Text(_s('Time: ${paper.timeLimit}'), style: pw.TextStyle(font: boldFont, fontSize: baseFontSize), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            widgets.add(pw.SizedBox(height: spacing));

            // 3. Questions Loop
            final List<QuestionSection> sectionsList = paper.sections.toList();
            for (int sectionIndex = 0; sectionIndex < sectionsList.length; sectionIndex++) {
              final QuestionSection section = sectionsList[sectionIndex];
              
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.only(top: spacing / 2, bottom: subSpacing / 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_s('${sectionIndex + 1}) '), style: pw.TextStyle(font: boldFont, fontSize: baseFontSize + 0.5)),
                      pw.Expanded(
                        child: pw.Text(_s(section.title), style: pw.TextStyle(font: boldFont, fontSize: baseFontSize + 0.5)),
                      ),
                      if (section.marksLabel.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10),
                          child: pw.Text(_s('[${section.marksLabel.replaceAll('[', '').replaceAll(']', '')}]'), style: pw.TextStyle(font: boldFont, fontSize: baseFontSize)),
                        ),
                    ],
                  ),
                ),
              );

              final List<QuestionItem> itemsList = section.items.toList();
              for (int itemIndex = 0; itemIndex < itemsList.length; itemIndex++) {
                final QuestionItem item = itemsList[itemIndex];
                final alpha = 'abcdefghijklmnopqrstuvwxyz';

                widgets.add(
                  pw.Padding(
                    padding: pw.EdgeInsets.only(left: 12, bottom: subSpacing),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (section.items.length > 1)
                          pw.SizedBox(
                            width: 18,
                            child: pw.Text(_s('${alpha[itemIndex]}) '), style: pw.TextStyle(font: font, fontSize: baseFontSize)),
                          ),
                        pw.Expanded(
                          child: pw.Text(_s(item.questionText), style: pw.TextStyle(font: font, fontSize: baseFontSize)),
                        ),
                        if (item.marks != null && item.marks!.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10),
                            child: pw.Text(_s('[${item.marks}]'), style: pw.TextStyle(font: boldFont, fontSize: baseFontSize - 1)),
                          ),
                      ],
                    ),
                  ),
                );

                final List<String> subQs = item.subQuestions.toList();
                if (subQs.isNotEmpty) {
                  widgets.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 32, bottom: 6),
                      child: pw.Wrap(
                        spacing: 25,
                        runSpacing: 4,
                        children: List<pw.Widget>.generate(subQs.length, (subIndex) {
                          final subText = subQs[subIndex].toString();
                          final roman = ['i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x'];

                          return pw.Container(
                            width: (totalItems > 60) ? 140 : 180,
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text(_s('${roman[subIndex]}) '), style: pw.TextStyle(font: font, fontSize: baseFontSize - 0.5)),
                                pw.Expanded(
                                  child: pw.Text(_s(subText), style: pw.TextStyle(font: font, fontSize: baseFontSize - 0.5)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }
              }
            }
            return widgets;
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${paper.className}_${paper.subject}_Exam.pdf',
      );
      return null;
    } catch (e, stack) {
      print('PDF Generation Error: $e');
      print(stack);
      return e.toString();
    }
  }

  static String _s(String text) => IndicShaper.shape(text ?? '');

  static String _getRoman(int number) {
    if (number <= 0) return "";
    final List<String> m = ["", "M", "MM", "MMM"];
    final List<String> c = ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"];
    final List<String> x = ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"];
    final List<String> i = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"];
    return m[number ~/ 1000] + c[(number % 1000) ~/ 100] + x[(number % 100) ~/ 10] + i[number % 10];
  }
}
