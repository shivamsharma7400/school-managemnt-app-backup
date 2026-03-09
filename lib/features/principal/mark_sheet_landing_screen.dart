import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';
import 'mark_sheet_screen.dart';

class MarkSheetLandingScreen extends StatelessWidget {
  const MarkSheetLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('Select Exam for Mark Sheets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scheduled_exams').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text('No exams scheduled yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(24),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final exam = ScheduledExam.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.modernPrimary.withOpacity(0.1),
                    child: Icon(Icons.description, color: AppColors.modernPrimary),
                  ),
                  title: Text(exam.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(
                    '${DateFormat('dd MMM').format(exam.startDate)} - ${DateFormat('dd MMM yyyy').format(exam.endDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => MarkSheetScreen(exam: exam),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
