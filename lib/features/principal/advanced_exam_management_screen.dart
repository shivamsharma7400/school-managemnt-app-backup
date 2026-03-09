import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';
import 'admit_card_screen.dart';
import 'teachers_setup_screen.dart';
import 'result_sheet_screen.dart';
import 'exam_access_permission_screen.dart';
import 'mark_sheet_screen.dart';

class AdvancedExamManagementScreen extends StatelessWidget {
  final ScheduledExam exam;

  const AdvancedExamManagementScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('Exam Management', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              exam.name,
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            _buildManagementCard(
              context,
              'Admit Card',
              'Generate and manage exam admit cards',
              Icons.badge,
              Colors.indigo,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdmitCardScreen(exam: exam),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildManagementCard(
              context,
              'Access Permissions',
              'Control what students can view',
              Icons.security,
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamAccessPermissionScreen(exam: exam),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildManagementCard(
              context,
              'Teachers Setup',
              'Assign invigilators and exam staff',
              Icons.person_add_alt_1,
              Colors.teal,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeachersSetupScreen(exam: exam),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildManagementCard(
              context,
              'Result Sheet',
              'Manage subject-wise result entries',
              Icons.analytics,
              Colors.amber[800]!,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultSheetScreen(exam: exam),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildManagementCard(
              context,
              'Mark Sheet',
              'Generate and print individual mark sheets',
              Icons.description,
              Colors.deepPurple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarkSheetScreen(exam: exam),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
