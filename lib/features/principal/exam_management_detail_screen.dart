import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';
import 'advanced_exam_management_screen.dart';
import 'exam_routine_screen.dart';
import 'exam_status_screen.dart';
import 'exam_question_list_screen.dart';

class ExamManagementDetailScreen extends StatelessWidget {
  final ScheduledExam exam;

  const ExamManagementDetailScreen({Key? key, required this.exam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text(exam.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            _buildManagementCard(
              context,
              'Exam Routine',
              'Manage subject-wise dates and times',
              Icons.calendar_month,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamRoutineScreen(exam: exam),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildManagementCard(
              context,
              'Exam Status',
              'Update current status (Upcoming/Ongoing/Completed)',
              Icons.info_outline,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamStatusScreen(exam: exam),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildManagementCard(
              context,
              'Exam Management',
              'Configure exam settings and rules',
              Icons.settings_suggest,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdvancedExamManagementScreen(exam: exam),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildManagementCard(
              context,
              'Exam Question',
              'Create and manage question papers',
              Icons.quiz_outlined,
              Colors.teal,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamQuestionListScreen(exam: exam),
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
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
