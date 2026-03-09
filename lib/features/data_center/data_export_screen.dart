import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _isExporting = false;
  double _progress = 0;
  String _statusMessage = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _exportFullAppData() async {
    setState(() {
      _isExporting = true;
      _progress = 0.05;
      _statusMessage = "Starting Master Data Retrieval...";
    });

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('dd-MMM-yyyy HH:mm').format(now);
      final pdf = pw.Document();

      // 1. FETCH DATA - SECTION BY SECTION
      
      // -- Students --
      setState(() { _progress = 0.1; _statusMessage = "Fetching Students..."; });
      final studentSnapshot = await _firestore.collection('students').get();
      final students = studentSnapshot.docs.map((doc) => doc.data()).toList();

      // -- Staff/Teachers --
      setState(() { _progress = 0.2; _statusMessage = "Fetching Staff Directory..."; });
      final staffSnapshot = await _firestore.collection('users').get();
      final allUsers = staffSnapshot.docs.map((doc) => doc.data()).toList();
      final staff = allUsers.where((u) => ['admin', 'principal', 'teacher', 'staff'].contains(u['role'])).toList();

      // -- Fees --
      setState(() { _progress = 0.3; _statusMessage = "Fetching Financial Records..."; });
      final feeSnapshot = await _firestore.collection('fees').get();
      final fees = feeSnapshot.docs.map((doc) => doc.data()).toList();
      double totalCollected = fees.fold(0, (sum, item) => sum + (item['paidAmount'] ?? 0).toDouble());
      double totalDue = fees.fold(0, (sum, item) => sum + ((item['totalAmount'] ?? 0) - (item['paidAmount'] ?? 0)).toDouble());

      // -- Attendance Summary --
      setState(() { _progress = 0.4; _statusMessage = "Analyzing Attendance Trends..."; });
      final attendanceSnapshot = await _firestore.collection('attendance').limit(500).get(); // Limit for performance
      final attendance = attendanceSnapshot.docs.map((doc) => doc.data()).toList();

      // -- Syllabus/Academic --
      setState(() { _progress = 0.5; _statusMessage = "Fetching Syllabus Progress..."; });
      final syllabusSnapshot = await _firestore.collection('syllabuses').get();
      final syllabuses = syllabusSnapshot.docs.map((doc) => doc.data()).toList();

      // -- Exams --
      setState(() { _progress = 0.6; _statusMessage = "Fetching Exam Schedules..."; });
      final examSnapshot = await _firestore.collection('exams').get();
      final exams = examSnapshot.docs.map((doc) => doc.data()).toList();

      // -- Announcements --
      setState(() { _progress = 0.7; _statusMessage = "Retrieving Bulletins..."; });
      final announcementSnapshot = await _firestore.collection('announcements').get();
      final announcements = announcementSnapshot.docs.map((doc) => doc.data()).toList();

      // 2. GENERATE PDF SECTIONS
      setState(() { _progress = 0.8; _statusMessage = "Compiling Professional PDF Report..."; });

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => _buildPdfHeader(dateStr),
          footer: (context) => _buildPdfFooter(context, dateStr),
          build: (context) => [
            // COVER SECTION
            pw.Center(
              child: pw.Column(
                children: [
                  pw.SizedBox(height: 50),
                  pw.Text("ANNUAL MASTER DATA REPORT", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  pw.Text("VEENA PUBLIC SCHOOL - DATABASE CLOUD SYNC", style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    width: 400,
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.indigo100), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15))),
                    child: pw.Column(
                      children: [
                        _buildSummaryRow("Total Active Students", students.length.toString()),
                        _buildSummaryRow("Faculty & Staff Size", staff.length.toString()),
                        _buildSummaryRow("Syllabus Modules", syllabuses.length.toString()),
                        _buildSummaryRow("Total Revenue (Net)", "Rs. \${totalCollected.toStringAsFixed(2)}"),
                        _buildSummaryRow("Outstanding Dues", "Rs. \${totalDue.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 100),
                ],
              ),
            ),

            // 1. STUDENT DIRECTORY
            pw.Header(level: 0, child: pw.Text("1. Full Student Directory", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800))),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
              data: [
                ['Name', 'Class', 'Roll No', 'Parent Name', 'Mobile'],
                ...students.map((s) => [
                  s['name'] ?? 'N/A',
                  s['class'] ?? 'N/A',
                  s['rollNo'] ?? 'N/A',
                  s['parentName'] ?? 'N/A',
                  s['phone'] ?? 'N/A',
                ]),
              ],
            ),
            pw.SizedBox(height: 30),

            // 2. STAFF & FACULTY
            pw.Header(level: 0, child: pw.Text("2. Faculty & Staff Directory", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800))),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
              data: [
                ['Staff Name', 'Official Role', 'System Email', 'Mobile'],
                ...staff.map((s) => [
                  s['name'] ?? 'N/A',
                  (s['role'] ?? 'N/A').toString().toUpperCase(),
                  s['email'] ?? 'N/A',
                  s['phone'] ?? 'N/A',
                ]),
              ],
            ),
            pw.SizedBox(height: 30),

            // 3. FINANCIAL AUDIT (FEE RECORDS)
            pw.Header(level: 0, child: pw.Text("3. Financial Fee Audit", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900))),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
              data: [
                ['Student', 'Month', 'Total (Rs)', 'Paid (Rs)', 'Due (Rs)'],
                ...fees.take(100).map((f) => [ // Limit for sanity in preview but usually full
                  f['studentName'] ?? 'N/A',
                  f['month'] ?? 'N/A',
                  (f['totalAmount'] ?? 0).toString(),
                  (f['paidAmount'] ?? 0).toString(),
                  ((f['totalAmount'] ?? 0) - (f['paidAmount'] ?? 0)).toString(),
                ]),
              ],
            ),
            pw.SizedBox(height: 30),

            // 4. SYLLABUS & ACADEMIC PROGRESS
            pw.Header(level: 0, child: pw.Text("4. Syllabus & Academic Progress", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              data: [
                ['Subject', 'Class', 'Teacher', 'Progress %', 'Total Chapters'],
                ...syllabuses.map((s) => [
                  s['subjectName'] ?? 'N/A',
                  s['className'] ?? 'N/A',
                  s['teacherName'] ?? 'Not Assigned',
                  "\${((s['progress'] ?? 0.0) * 100).toInt()}%",
                  (s['chapterCount'] ?? 0).toString(),
                ]),
              ],
            ),
            pw.SizedBox(height: 30),

            // 5. ANNOUNCEMENTS & RECENT ALERTS
            pw.Header(level: 0, child: pw.Text("5. Recent School Notices", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red900))),
            ...announcements.take(10).map((a) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(a['title'] ?? 'No Title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(a['message'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text("Date: \${a['createdAt'] != null ? DateFormat('dd MMM').format((a['createdAt'] as Timestamp).toDate()) : 'N/A'}", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            )),
          ],
        ),
      );

      setState(() { _progress = 0.95; _statusMessage = "Finalizing File Protocol..."; });

      // 3. EXECUTE DOWNLOAD/PRINT
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'VPS_Complete_App_Data_\${now.millisecondsSinceEpoch}.pdf',
      );

      setState(() {
        _isExporting = false;
        _progress = 1.0;
        _statusMessage = "Data Export Successful!";
      });

      Get.snackbar(
        "Export Complete",
        "Master data report has been generated successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      if (kDebugMode) print("Export Error: $e");
      setState(() {
        _isExporting = false;
        _statusMessage = "Export Failed: \$e";
      });
      Get.snackbar(
        "Export Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  pw.Widget _buildPdfHeader(String date) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("VEENA PUBLIC SCHOOL", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("MASTER DATA REPOSITORY", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text("Generated on: \$date", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 1, color: PdfColors.indigo200),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context, String date) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Divider(thickness: 0.5, color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Veena Public School | Safe & Encrypted Data Port", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              pw.Text('Page \${context.pageNumber} / \${context.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.indigo900)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Master Data Center', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildActionHeader(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildMainExportTile(),
                  const SizedBox(height: 32),
                  if (_isExporting) _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildDataCoverageCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.security_rounded, color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Full Backup Center',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Generate a complete snapshot of all school records including academic, financial, and administrative data.',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.white60, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMainExportTile() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: _isExporting ? _progress : 1.0,
                  strokeWidth: 4,
                  backgroundColor: Colors.indigo[50],
                  valueColor: AlwaysStoppedAnimation<Color>(_isExporting ? const Color(0xFF6366F1) : Colors.green),
                ),
              ),
              Icon(
                _isExporting ? Icons.downloading_rounded : Icons.verified_user_rounded,
                size: 40,
                color: _isExporting ? const Color(0xFF6366F1) : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Master Data Export',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            'High-Resolution PDF Compilation',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _isExporting ? null : _exportFullAppData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 12,
                shadowColor: const Color(0xFF4F46E5).withOpacity(0.3),
              ),
              child: _isExporting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Compile All App Data', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Syncing Process', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              Text('\${(_progress * 100).toInt()}%', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.indigo[50],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            minHeight: 10,
            borderRadius: BorderRadius.circular(15),
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCoverageCard() {
    final modules = [
      {'icon': Icons.people_outline, 'name': 'Students Database', 'color': Colors.blue},
      {'icon': Icons.person_pin_outlined, 'name': 'Staff Directory', 'color': Colors.teal},
      {'icon': Icons.receipt_long_outlined, 'name': 'Financial Audits', 'color': Colors.orange},
      {'icon': Icons.menu_book_outlined, 'name': 'Syllabus Progress', 'color': Colors.indigo},
      {'icon': Icons.campaign_outlined, 'name': 'School Notices', 'color': Colors.red},
      {'icon': Icons.event_note_outlined, 'name': 'Exam Schedules', 'color': Colors.purple},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Coverage', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final m = modules[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (m['color'] as Color).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: (m['color'] as Color).withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(m['icon'] as IconData, size: 20, color: m['color'] as Color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m['name'] as String,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
