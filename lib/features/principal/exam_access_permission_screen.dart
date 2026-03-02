import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';

class ExamAccessPermissionScreen extends StatefulWidget {
  final ScheduledExam exam;

  const ExamAccessPermissionScreen({Key? key, required this.exam}) : super(key: key);

  @override
  _ExamAccessPermissionScreenState createState() => _ExamAccessPermissionScreenState();
}

class _ExamAccessPermissionScreenState extends State<ExamAccessPermissionScreen> {
  late bool _routineAccess;
  late bool _admitCardAccess;
  late bool _resultAccess;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final permissions = widget.exam.safeAccessPermissions;
    _routineAccess = permissions['routine'] ?? false;
    _admitCardAccess = permissions['admitCard'] ?? false;
    _resultAccess = permissions['result'] ?? false;
  }

  Future<void> _updatePermission(String key, bool value) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .update({
            'accessPermissions.$key': value,
          });
      
      setState(() {
        if (key == 'routine') _routineAccess = value;
        if (key == 'admitCard') _admitCardAccess = value;
        if (key == 'result') _resultAccess = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access permission updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('Access Permissions', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(24),
            children: [
              Text(
                'Student Visibility Settings',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Turn on the switches to allow students to see these details on their dashboard for ${widget.exam.name}.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  activeColor: AppColors.modernPrimary,
                  title: Text('Exam Routine', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Allow students to view and download the exam routine.'),
                  secondary: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.date_range, color: Colors.blue),
                  ),
                  value: _routineAccess,
                  onChanged: (val) => _updatePermission('routine', val),
                ),
              ),
              SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  activeColor: AppColors.modernPrimary,
                  title: Text('Admit Card', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Allow students with clear dues to view and print their admit cards.'),
                  secondary: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.badge, color: Colors.orange),
                  ),
                  value: _admitCardAccess,
                  onChanged: (val) => _updatePermission('admitCard', val),
                ),
              ),
              SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  activeColor: AppColors.modernPrimary,
                  title: Text('Mark Sheet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Allow students to view their result mark sheets.'),
                  secondary: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.description, color: Colors.green),
                  ),
                  value: _resultAccess,
                  onChanged: (val) => _updatePermission('result', val),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator(color: AppColors.modernPrimary)),
            ),
        ],
      ),
    );
  }
}
