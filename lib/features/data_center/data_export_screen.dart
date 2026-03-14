import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:html' as html;

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  int _selectedModuleIndex = 0;
  bool _isExporting = false;
  double _progress = 0;
  String _statusMessage = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _modules = [
    {'icon': Icons.people_outline, 'name': 'Students Database', 'color': Colors.blue, 'collection': 'students'},
    {'icon': Icons.person_pin_outlined, 'name': 'Staff Directory', 'color': Colors.teal, 'collection': 'users'},
    {'icon': Icons.receipt_long_outlined, 'name': 'Financial Audits', 'color': Colors.orange, 'collection': 'fees'},
    {'icon': Icons.menu_book_outlined, 'name': 'Syllabus Progress', 'color': Colors.indigo, 'collection': 'syllabuses'},
    {'icon': Icons.campaign_outlined, 'name': 'School Notices', 'color': Colors.red, 'collection': 'announcements'},
    {'icon': Icons.event_note_outlined, 'name': 'Exam Schedules', 'color': Colors.purple, 'collection': 'exams'},
  ];

  Future<void> _exportSelectedData() async {
    final selectedModule = _modules[_selectedModuleIndex];
    
    setState(() {
      _isExporting = true;
      _progress = 0.05;
      _statusMessage = "Starting ${selectedModule['name']} Retrieval...";
    });

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('dd-MMM-yyyy HH:mm').format(now);
      List<List<dynamic>> csvData = [];

      // Add Header
      csvData.add(['VEENA PUBLIC SCHOOL - DATA EXPORT']);
      csvData.add(['Module:', selectedModule['name']]);
      csvData.add(['Generated on:', dateStr]);
      csvData.add([]);

      if (selectedModule['collection'] == 'students') {
        setState(() { _progress = 0.3; _statusMessage = "Fetching Students..."; });
        final snapshot = await _firestore.collection('users')
            .where('role', whereIn: ['student', 'passed_out'])
            .get();
        csvData.add(['Name', 'Class', 'Roll No/Adm No', 'Parent Name', 'Mobile', 'Address', 'Gender', 'Status', 'Due Balance (₹)']);
        for (var doc in snapshot.docs) {
          final s = doc.data();
          csvData.add([
            s['name'] ?? 'N/A',
            s['classId'] ?? s['class'] ?? 'N/A',
            s['admNo'] ?? s['rollNo'] ?? 'N/A',
            s['parentName'] ?? 'N/A',
            s['phone'] ?? 'N/A',
            s['address'] ?? 'N/A',
            s['gender'] ?? 'N/A',
            (s['role'] ?? 'student').toString().toUpperCase(),
            (s['currentDue'] ?? 0).toString(),
          ]);
        }
      } else if (selectedModule['collection'] == 'users') {
        setState(() { _progress = 0.3; _statusMessage = "Fetching Staff Directory..."; });
        final snapshot = await _firestore.collection('users')
            .where('role', whereIn: ['admin', 'principal', 'teacher', 'staff', 'driver', 'management'])
            .get();
        csvData.add(['Staff Name', 'Official Role', 'System Email', 'Mobile', 'Address', 'Monthly Salary (₹)', 'Unpaid Balance (₹)']);
        for (var doc in snapshot.docs) {
          final s = doc.data();
          csvData.add([
            s['name'] ?? 'N/A',
            (s['role'] ?? 'N/A').toString().toUpperCase(),
            s['email'] ?? 'N/A',
            s['phone'] ?? 'N/A',
            s['address'] ?? 'N/A',
            (s['monthlySalary'] ?? 0).toString(),
            (s['salaryDue'] ?? 0).toString(),
          ]);
        }
      } else if (selectedModule['collection'] == 'fees') {
        setState(() { _progress = 0.2; _statusMessage = "Fetching Transaction Ledger..."; });
        
        // 1. Fetch all transactions
        final transactionsSnapshot = await _firestore.collection('transactions').get();
        List<Map<String, dynamic>> allEntries = [];
        
        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data();
          final type = data['type']?.toString() ?? '';
          if (type == 'Fee Payment' || type == 'Manual Income' || type == 'Manual Expense') {
            allEntries.add({
              'date': (data['date'] as Timestamp).toDate(),
              'category': type.contains('Fee') ? 'Student Fee' : (type.contains('Income') ? 'Misc Income' : 'Direct Expense'),
              'description': data['description'] ?? (type == 'Fee Payment' ? "Fee: ${data['studentName']}" : 'Manual Entry'),
              'type': (type == 'Fee Payment' || type == 'Manual Income') ? 'INCOME' : 'EXPENSE',
              'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
            });
          }
        }

        // 2. Fetch Staff Salaries
        setState(() { _progress = 0.4; _statusMessage = "Accessing Payroll Records..."; });
        final staffSnapshot = await _firestore.collection('users')
            .where('role', whereIn: ['teacher', 'driver', 'staff'])
            .get();
        
        for (var staffDoc in staffSnapshot.docs) {
          final historySnapshot = await staffDoc.reference.collection('salary_history')
              .where('type', isEqualTo: 'credit')
              .get();
          
          for (var histDoc in historySnapshot.docs) {
            final hData = histDoc.data();
            if (hData['date'] != null) {
              allEntries.add({
                'date': (hData['date'] as Timestamp).toDate(),
                'category': 'Payroll',
                'description': "Salary: ${staffDoc.data()['name'] ?? 'Staff'} (${hData['month'] ?? 'N/A'})",
                'type': 'EXPENSE',
                'amount': (hData['amount'] as num?)?.toDouble() ?? 0.0,
              });
            }
          }
        }

        // 3. Group by Month and Year
        allEntries.sort((a, b) => b['date'].compareTo(a['date']));
        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var entry in allEntries) {
          String monthKey = DateFormat('MMMM yyyy').format(entry['date']);
          if (!grouped.containsKey(monthKey)) grouped[monthKey] = [];
          grouped[monthKey]!.add(entry);
        }

        // 4. Build CSV Rows
        for (var monthKey in grouped.keys) {
          csvData.add(['--- $monthKey ---']);
          csvData.add(['Date', 'Category', 'Description', 'Type', 'Amount (Rs)']);
          
          double monthIncome = 0;
          double monthExpense = 0;
          
          for (var entry in grouped[monthKey]!) {
            csvData.add([
              DateFormat('dd/MM/yyyy').format(entry['date']),
              entry['category'],
              entry['description'],
              entry['type'],
              entry['amount'].toString(),
            ]);
            
            if (entry['type'] == 'INCOME') monthIncome += entry['amount'];
            else monthExpense += entry['amount'];
          }
          
          csvData.add(['', '', 'TOTAL MONTHLY INCOME:', '', monthIncome.toString()]);
          csvData.add(['', '', 'TOTAL MONTHLY EXPENSE:', '', monthExpense.toString()]);
          csvData.add(['', '', 'NET MONTHLY BALANCE:', '', (monthIncome - monthExpense).toString()]);
          csvData.add([]); // Spacing between months
        }
      } else if (selectedModule['collection'] == 'syllabuses') {
        setState(() { _progress = 0.3; _statusMessage = "Fetching Syllabus Progress..."; });
        final snapshot = await _firestore.collection('syllabuses').get();
        csvData.add(['Subject', 'ClassID', 'Teacher', 'Progress %', 'Total Chapters']);
        for (var doc in snapshot.docs) {
          final s = doc.data();
          csvData.add([
            s['subjectName'] ?? 'N/A',
            s['classId'] ?? 'N/A',
            s['teacherName'] ?? 'Not Assigned',
            "${((s['progress'] ?? 0.0) * 100).toInt()}%",
            (s['chapterCount'] ?? 0).toString(),
          ]);
        }
      } else if (selectedModule['collection'] == 'announcements') {
        setState(() { _progress = 0.3; _statusMessage = "Retrieving Notices..."; });
        final snapshot = await _firestore.collection('announcements').get();
        csvData.add(['Title', 'Message Content', 'Target Audience', 'Date']);
        for (var doc in snapshot.docs) {
          final a = doc.data();
          csvData.add([
            a['title'] ?? 'No Title',
            (a['content'] ?? a['message'] ?? '').replaceAll('\n', ' '),
            (a['targetAudience'] ?? 'All').toString().toUpperCase(),
            a['date'] != null ? DateFormat('dd MMM yyyy').format((a['date'] as Timestamp).toDate()) : 'N/A',
          ]);
        }
      } else if (selectedModule['collection'] == 'exams') {
        setState(() { _progress = 0.2; _statusMessage = "Fetching Exam Metadata..."; });
        
        // 1. Fetch Students Map (ID -> Name, RollNo)
        final studentsSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'student').get();
        final studentMap = { for (var doc in studentsSnapshot.docs) doc.id: { 'name': doc.data()['name'], 'roll': doc.data()['admNo'] ?? doc.data()['rollNo'] ?? 'N/A' } };
        
        // 2. Fetch Classes Map (ID -> Name)
        final classesSnapshot = await _firestore.collection('classes').get();
        final classMap = { for (var doc in classesSnapshot.docs) doc.id: doc.data()['name'] };
        
        setState(() { _progress = 0.4; _statusMessage = "Compiling Result Sheets..."; });
        final snapshot = await _firestore.collection('scheduled_exams').get();
        
        for (var examDoc in snapshot.docs) {
          final e = examDoc.data();
          csvData.add(['--- EXAM: ${e['name'] ?? 'N/A'} ---']);
          csvData.add(['Dates:', '${DateFormat('dd/MM/yyyy').format((e['startDate'] as Timestamp).toDate())} to ${DateFormat('dd/MM/yyyy').format((e['endDate'] as Timestamp).toDate())}']);
          csvData.add(['Status:', (e['status'] ?? 'N/A').toString().toUpperCase()]);
          csvData.add([]); // Spacing

          // Fetch Class Results Sub-collection
          final classResultsSnapshot = await examDoc.reference.collection('class_results').get();
          
          if (classResultsSnapshot.docs.isEmpty) {
            csvData.add(['Result Status:', 'No Results Published Yet']);
            csvData.add([]);
          } else {
            for (var classDoc in classResultsSnapshot.docs) {
              final className = classMap[classDoc.id] ?? 'Class: ${classDoc.id}';
              csvData.add(['[ $className ]']);
              
              final studentResults = classDoc.data(); // Map<studentId, Map<subject, marks>>
              
              // Find all subjects in this class result to create headers
              Set<String> subjects = {};
              for (var res in studentResults.values) {
                if (res is Map) subjects.addAll(res.keys.cast<String>());
              }
              final sortedSubjects = subjects.toList()..sort();
              
              csvData.add(['Roll No', 'Student Name', ...sortedSubjects, 'Total', 'Percentage', 'Grade']);
              
              for (var entry in studentResults.entries) {
                final studentId = entry.key;
                final marksMap = entry.value as Map<String, dynamic>;
                final studentInfo = studentMap[studentId] ?? { 'name': 'Unknown Student', 'roll': 'N/A' };
                
                double totalObtained = 0;
                List<dynamic> row = [studentInfo['roll'], studentInfo['name']];
                
                for (var sub in sortedSubjects) {
                  final mark = double.tryParse(marksMap[sub]?.toString() ?? '0') ?? 0;
                  row.add(mark);
                  totalObtained += mark;
                }
                
                double percentage = (sortedSubjects.isNotEmpty) ? (totalObtained / (sortedSubjects.length * 100)) * 100 : 0;
                String grade = 'F';
                if (percentage >= 90) grade = 'A+';
                else if (percentage >= 80) grade = 'A';
                else if (percentage >= 70) grade = 'B';
                else if (percentage >= 60) grade = 'C';
                else if (percentage >= 40) grade = 'D';

                row.addAll([totalObtained, "${percentage.toStringAsFixed(1)}%", grade]);
                csvData.add(row);
              }
              csvData.add([]); // Spacing between classes
            }
          }
          csvData.add(['--------------------------------------------------']);
          csvData.add([]); // Spacing between exams
        }
      }

      String csvString = const ListToCsvConverter().convert(csvData);

      setState(() { _progress = 0.95; _statusMessage = "Finalizing Data Stream..."; });

      // 3. EXECUTE DOWNLOAD
      if (kIsWeb) {
        final bytes = utf8.encode(csvString);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "${selectedModule['collection']}_export_${now.millisecondsSinceEpoch}.csv")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        Get.snackbar(
          "Export Format",
          "CSV export is optimized for Web.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      setState(() {
        _isExporting = false;
        _progress = 1.0;
        _statusMessage = "Data Export Successful!";
      });

      Get.snackbar(
        "Export Complete",
        "${selectedModule['name']} has been exported successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      if (kDebugMode) print("Export Error: $e");
      setState(() {
        _isExporting = false;
        _statusMessage = "Export Failed: $e";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Data Export Center', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                  _buildDataCoverageCard(),
                  const SizedBox(height: 32),
                  _buildMainExportTile(),
                  const SizedBox(height: 32),
                  if (_isExporting) _buildProgressCard(),
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
                'Selective Export',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Select a specific data module above and generate a high-precision CSV export for your records.',
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
            'Export Module',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            'High-Resolution CSV Compilation',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _isExporting ? null : _exportSelectedData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 12,
                shadowColor: const Color(0xFF4F46E5).withOpacity(0.3),
              ),
              child: _isExporting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Export ${_modules[_selectedModuleIndex]['name']}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
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
              Text('${(_progress * 100).toInt()}%', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Data Type', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: _modules.length,
            itemBuilder: (context, index) {
              final m = _modules[index];
              final isSelected = _selectedModuleIndex == index;
              return InkWell(
                onTap: () => setState(() => _selectedModuleIndex = index),
                borderRadius: BorderRadius.circular(15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? (m['color'] as Color).withOpacity(0.15) : (m['color'] as Color).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? (m['color'] as Color) : (m['color'] as Color).withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(m['icon'] as IconData, size: 20, color: m['color'] as Color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 11, 
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
                            color: isSelected ? (m['color'] as Color) : Colors.grey[800],
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, size: 16, color: m['color'] as Color),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
