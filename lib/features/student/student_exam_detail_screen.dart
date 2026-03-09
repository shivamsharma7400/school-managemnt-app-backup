import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/student_exam_pdf_service.dart';

class StudentExamDetailScreen extends StatefulWidget {
  final ScheduledExam exam;

  const StudentExamDetailScreen({super.key, required this.exam});

  @override
  _StudentExamDetailScreenState createState() => _StudentExamDetailScreenState();
}

class _StudentExamDetailScreenState extends State<StudentExamDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _routineConfig;
  Map<String, dynamic>? _routineAssignments;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    try {
      if (authService.user?.uid != null) {
        _studentData = await userService.getUserData(authService.user!.uid);
      }

      final doc = await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .get();

      if (doc.exists) {
        _routineConfig = doc.data()?['routine_config'];
        _routineAssignments = doc.data()?['routine_assignments'];
      }
    } catch (e) {
      print('Error fetching student exam details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.exam.name)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final permissions = widget.exam.safeAccessPermissions;

    final hasRoutineAccess = permissions['routine'] == true;
    final hasResultAccess = permissions['result'] == true;
    
    // Admit card access requires toggle ON AND zero dues
    final double dueAmount = (_studentData?['currentDue'] as num?)?.toDouble() ?? 0.0;
    final hasAdmitCardAccess = permissions['admitCard'] == true && dueAmount <= 0;

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text(
          widget.exam.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (hasRoutineAccess) ...[
              _buildOptionCard(
                context,
                title: 'Exam Routine',
                icon: Icons.date_range,
                color: Colors.blue,
                onTap: () {
                  StudentExamPdfService.printExamRoutine(
                    widget.exam,
                    _routineConfig,
                    _routineAssignments,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            if (hasAdmitCardAccess && _studentData != null) ...[
              _buildOptionCard(
                context,
                title: 'Exam Admit Card',
                icon: Icons.badge,
                color: Colors.orange,
                onTap: () {
                  // Pass the fetched studentData and routine constraints to the PDF generator
                  StudentExamPdfService.printAdmitCard(
                    widget.exam,
                    _studentData!,
                    _routineConfig,
                    _routineAssignments
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Show a locked admit card if permission is on but they have dues
            if (permissions['admitCard'] == true && dueAmount > 0) ...[
              _buildLockedOptionCard(
                context,
                title: 'Exam Admit Card',
                icon: Icons.lock,
                color: Colors.grey,
                message: 'Clear your dues to access the Admit Card.',
              ),
              const SizedBox(height: 16),
            ],

            if (hasResultAccess) ...[
              _buildOptionCard(
                context,
                title: 'Mark Sheet',
                icon: Icons.assignment_turned_in,
                color: Colors.green,
                onTap: () async {
                  if (authService.user?.uid != null && _studentData != null) {
                    // Show loading indicator
                    showDialog(
                      context: context, 
                      barrierDismissible: false,
                      builder: (c) => Center(child: CircularProgressIndicator())
                    );
                    
                    try {
                      // 1. Fetch class results for this exam
                      final classId = _studentData!['classId'];
                      final resultDoc = await FirebaseFirestore.instance
                          .collection('scheduled_exams')
                          .doc(widget.exam.id)
                          .collection('class_results')
                          .doc(classId)
                          .get();
                          
                      if (!resultDoc.exists) {
                        Navigator.pop(context); // Remove loading
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Results not published yet.')));
                        return;
                      }
                      
                      final allResults = resultDoc.data()!;
                      final studentMarks = Map<String, dynamic>.from(allResults[authService.user!.uid] ?? {});
                      
                      if (studentMarks.isEmpty) {
                        Navigator.pop(context); // Remove loading
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your results are not available.')));
                        return;
                      }

                      // 2. Prepare subjects list
                      List<Map<String, dynamic>> previewSubjects = [];
                      if (_routineConfig != null && _routineConfig!['subjects'] != null) {
                        final rawSubjects = _routineConfig!['subjects'] as List;
                        previewSubjects = rawSubjects.map((s) {
                          if (s is String) return {'name': s, 'fullMarks': 100.0};
                          return Map<String, dynamic>.from(s);
                        }).toList();
                      } else {
                        previewSubjects = studentMarks.keys.where((k) => k != 'total').map((k) => {'name': k, 'fullMarks': 100.0}).toList();
                      }

                      Navigator.pop(context); // Remove loading before generation
                      
                      // 3. Generate PDF
                      await StudentExamPdfService.printMarkSheet(
                        widget.exam,
                        _studentData!,
                        studentMarks,
                        previewSubjects,
                      );

                    } catch (e) {
                      Navigator.pop(context); // Remove loading on error
                      print('Error preparing mark sheet: $e');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load mark sheet.')));
                    }
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User details not found')),
                    );
                  }
                },
              ),
            ],

            if (!hasRoutineAccess && permissions['admitCard'] != true && !hasResultAccess)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: Column(
                    children: [
                      Icon(Icons.visibility_off, size: 60, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Details are not yet available for this exam.',
                        style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLockedOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
