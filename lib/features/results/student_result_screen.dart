import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/result_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/result_model.dart';
import '../../core/constants/app_constants.dart';

class StudentResultScreen extends StatelessWidget {
  final String? studentId;
  final String? studentName;
  final String? studentClass;
  final String? studentRoll;
  final String? studentAdmNo;

  const StudentResultScreen({
    super.key, 
    this.studentId, 
    this.studentName, 
    this.studentClass, 
    this.studentRoll,
    this.studentAdmNo,
  });

  @override
  Widget build(BuildContext context) {
    // If studentId is passed (e.g. from Principal view), use it. otherwise use current logged-in user.
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;
    
    final targetStudentId = studentId ?? currentUserId;
    final displayName = studentName ?? authService.userName;
    final displayClass = studentClass ?? authService.classId ?? 'N/A';
    // For roll number, we usually don't have it in AuthService easily unless stored in profile. 
    // But ExamResult model has roll number, so we can use that for display if needed or from arguments.
    
    if (targetStudentId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Results')),
        body: Center(child: Text("No student identified")),
      );
    }

    final bool isViewerMode = studentId != null; // True if principal/teacher is viewing

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isViewerMode ? "$displayName's Results" : 'My Report Cards'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ExamResult>>(
         future: Provider.of<ResultService>(context).getResultsForStudent(targetStudentId),
         builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_late, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No results found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final results = snapshot.data!;
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(targetStudentId).snapshots(),
              builder: (context, userSnapshot) {
                String admNo = studentAdmNo ?? 'N/A';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                   admNo = (userSnapshot.data!.data() as Map<String, dynamic>)['admNo'] ?? 'N/A';
                }
                
                return ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (ctx, i) => SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    return _buildReportCard(context, results[index], displayName, displayClass, admNo);
                  },
                );
              },
            );
         },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ExamResult result, String studentName, String className, String admNo) {
    final double percentage = (result.totalFullMarks > 0) 
        ? (result.totalObtainedMarks / result.totalFullMarks * 100) 
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Paper-like rounded corners
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // 1. Header (School Branding)
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.03),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                   Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/logos/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "OFFICIAL REPORT CARD",
                        style: TextStyle(fontSize: 10, color: Colors.grey[600], letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.examName,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // 2. Student Info Grid
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem("STUDENT NAME", studentName),
                    _buildInfoItem("CLASS", "Class $className"),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use roll number from the result object as it was frozen at exam time
                    _buildInfoItem("ROLL NO", result.rollNumber),
                    _buildInfoItem("ADM NO", admNo),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem("DATE", DateFormat('dd MMM yyyy').format(DateTime.now())), 
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // 3. Marks Table
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2), // Subject
                1: FlexColumnWidth(1), // Full
                2: FlexColumnWidth(1), // Obtained
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Table Header
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1))
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text("SUBJECT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600])),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text("FULL MARKS", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600])),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text("OBTAINED", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600])),
                    ),
                  ],
                ),
                // Data Rows
                ...result.subjects.map((subj) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(subj['subject'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text("${subj['full']}", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "${subj['obtained']}", 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[300]),

          // 4. Footer Summary (Total & Grade)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50], 
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("GRAND TOTAL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text(
                      "${result.totalObtainedMarks.toStringAsFixed(0)} / ${result.totalFullMarks.toStringAsFixed(0)}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PERCENTAGE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text(
                      "${percentage.toStringAsFixed(1)}%",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getGradeColor(result.grade),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: _getGradeColor(result.grade).withOpacity(0.3), blurRadius: 6, offset: Offset(0, 3))]
                  ),
                  child: Column(
                    children: [
                      Text("GRADE", style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                      Text(
                        result.grade,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 5. Signature Placeholder
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 20, right: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Placeholder for signature image or line
                  Container(width: 80, height: 1, color: Colors.grey[400]),
                  SizedBox(height: 4),
                  Text("PRINCIPAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.blue;
    if (grade.startsWith('C')) return Colors.orange;
    if (grade.startsWith('D')) return Colors.deepOrange;
    return Colors.red;
  }
}
