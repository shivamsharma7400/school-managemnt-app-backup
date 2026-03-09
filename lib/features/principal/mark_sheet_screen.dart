import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/utils/drive_helper.dart';
import '../../data/models/scheduled_exam_model.dart';
import '../../data/services/class_service.dart';
import '../../data/models/class_model.dart';

class MarkSheetScreen extends StatefulWidget {
  final ScheduledExam exam;

  const MarkSheetScreen({super.key, required this.exam});

  @override
  _MarkSheetScreenState createState() => _MarkSheetScreenState();
}

class _MarkSheetScreenState extends State<MarkSheetScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  TabController? _tabController;
  List<ClassModel> _classes = [];
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  
  // Storage for all marks: {classId: {studentId: {subject: marks}}}
  final Map<String, Map<String, dynamic>> _resultsData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 0. Load subjects and marks from routine config
      final examDoc = await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .get();
      
      if (examDoc.exists && examDoc.data()!.containsKey('routine_config')) {
        final config = examDoc.data()!['routine_config'] as Map<String, dynamic>;
        final rawSubjects = config['subjects'] ?? [];
        _subjects = (rawSubjects as List).map((s) {
          if (s is String) return {'name': s, 'fullMarks': 100.0};
          return Map<String, dynamic>.from(s);
        }).toList();
      }

      // 1. Load classes
      _classes = await Provider.of<ClassService>(context, listen: false).fetchAllClasses();
      _classes.sort((a, b) {
        final indexA = AppConstants.schoolClasses.indexOf(a.name);
        final indexB = AppConstants.schoolClasses.indexOf(b.name);
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        return a.name.compareTo(b.name);
      });

      if (_classes.isNotEmpty) {
        _tabController = TabController(length: _classes.length, vsync: this);
      }

      // 2. Load all results for this exam
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .collection('class_results')
          .get();

      for (var doc in resultsSnapshot.docs) {
        _resultsData[doc.id] = doc.data();
      }

      // 3. Load basic student data
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      _allStudents = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Find and attach class name for report card
        final classModel = _classes.firstWhere(
          (c) => c.id == data['classId'],
          orElse: () => ClassModel(id: '', name: 'N/A', teacherId: ''),
        );
        data['className'] = classModel.name;
        
        return data;
      }).toList();
    } catch (e) {
      print('Error loading Mark Sheet data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _printMarkSheet(Map<String, dynamic> student, String currentClassName) async {
    final classId = student['classId'];
    final studentId = student['id'];
    
    final classResults = _resultsData[classId] ?? {};
    final studentMarks = Map<String, dynamic>.from(classResults[studentId] ?? {});
    
    if (studentMarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No results found for ${student['name']}. Please fill the Result Sheet first.')),
      );
      return;
    }

    // Use subjects from routine config if available
    List<Map<String, dynamic>> previewSubjects = _subjects;
    if (previewSubjects.isEmpty) {
      previewSubjects = studentMarks.keys.where((k) => k != 'total').map((k) => {'name': k, 'fullMarks': 100.0}).toList();
    }

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
                        _buildPdfDetailLine('Examination :', widget.exam.name, font, fontBold),
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
                      _buildPdfTableCell('SUBJECT', fontBold, isHeader: true),
                      _buildPdfTableCell('MAX MARKS', fontBold, isHeader: true),
                      _buildPdfTableCell('OBTAINED', fontBold, isHeader: true),
                    ],
                  ),
                  ...previewSubjects.map((sub) => pw.TableRow(
                    children: [
                      _buildPdfTableCell(sub['name'].toString().toUpperCase(), font),
                      _buildPdfTableCell(sub['fullMarks'].toString(), font),
                      _buildPdfTableCell(studentMarks[sub['name']]?.toString() ?? '0', fontBold),
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

  pw.Widget _buildPdfDetailLine(String label, String value, pw.Font font, pw.Font fontBold) {
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

  pw.Widget _buildPdfTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: isHeader ? 10 : 10),
      ),
    );
  }

  pw.Widget _buildPdfSummaryItem(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900)),
      ],
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    if (percentage >= 33) return 'P';
    return 'F';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('Mark Sheets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: (_tabController != null && _classes.isNotEmpty) ? TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: _classes.map((c) => Tab(text: 'Class ${c.name}')).toList(),
        ) : null,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _tabController == null 
              ? Center(child: Text('No classes found'))
              : TabBarView(
                  controller: _tabController,
                  children: _classes.map((c) => _buildStudentList(c)).toList(),
                ),
    );
  }

  Widget _buildStudentList(ClassModel classModel) {
    final classStudents = _allStudents.where((s) => s['classId'] == classModel.id).toList();
    final filteredClassStudents = classStudents.where((s) {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) return true;
      return (s['name'] ?? '').toLowerCase().contains(query) || 
             (s['admNo']?.toString() ?? '').contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search in Class ${classModel.name}...',
                prefixIcon: Icon(Icons.search, color: AppColors.modernPrimary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: filteredClassStudents.isEmpty 
                ? Center(child: Text('No students found in Class ${classModel.name}.', style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredClassStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredClassStudents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.modernPrimary.withOpacity(0.1),
                            child: Text(student['name']?[0] ?? '?', style: const TextStyle(color: AppColors.modernPrimary, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(student['name'] ?? 'N/A', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          subtitle: Text('Adm No: ${student['admNo']} | Sec: ${(student['customData'] as Map?)?['Sec'] ?? 'N/A'}'),
                          trailing: ElevatedButton(
                            onPressed: () => _printMarkSheet(student, classModel.name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.modernPrimary,
                              side: BorderSide(color: AppColors.modernPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Preview'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
