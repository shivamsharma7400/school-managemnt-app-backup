import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';
import 'exam_management_detail_screen.dart';

class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  _ExamSetupScreenState createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _scheduleNewExam() async {
    final nameController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Schedule New Exam', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Exam Name',
                      hintText: 'e.g., Final Term 2026',
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text(startDate == null ? 'Select Start Date' : 'Start: ${DateFormat('dd MMM yyyy').format(startDate!)}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: Text(endDate == null ? 'Select End Date' : 'End: ${DateFormat('dd MMM yyyy').format(endDate!)}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && startDate != null && endDate != null) {
                      await _firestore.collection('scheduled_exams').add({
                        'name': nameController.text,
                        'startDate': Timestamp.fromDate(startDate!),
                        'endDate': Timestamp.fromDate(endDate!),
                        'status': 'Upcoming',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('Exam Setup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _scheduleNewExam,
                icon: Icon(Icons.add),
                label: Text('Schedule New Exam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.modernPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Recent Scheduled Exams',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('scheduled_exams').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text('No exams scheduled yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final exam = ScheduledExam.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(exam.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(
                          '${DateFormat('dd MMM').format(exam.startDate)} - ${DateFormat('dd MMM yyyy').format(exam.endDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ExamManagementDetailScreen(exam: exam),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
