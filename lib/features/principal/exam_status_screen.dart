import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';

class ExamStatusScreen extends StatefulWidget {
  final ScheduledExam exam;

  const ExamStatusScreen({Key? key, required this.exam}) : super(key: key);

  @override
  _ExamStatusScreenState createState() => _ExamStatusScreenState();
}

class _ExamStatusScreenState extends State<ExamStatusScreen> {
  late String _currentStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.exam.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .update({'status': newStatus});
      
      setState(() {
        _currentStatus = newStatus;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Widget _buildStatusCard(String status, String description, IconData icon, Color color) {
    bool isSelected = _currentStatus == status;
    return Card(
      elevation: isSelected ? 8 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _updateStatus(status),
        borderRadius: BorderRadius.circular(16),
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
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color)
              else
                Icon(Icons.radio_button_off, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('Exam Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: double.infinity),
                Text(
                  widget.exam.name,
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.modernPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current Status: $_currentStatus',
                    style: TextStyle(color: AppColors.modernPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 40),
                _buildStatusCard(
                  'Upcoming',
                  'Exam is scheduled but hasn\'t started yet.',
                  Icons.schedule,
                  Colors.blue,
                ),
                SizedBox(height: 16),
                _buildStatusCard(
                  'Ongoing',
                  'Exam is currently in progress.',
                  Icons.play_circle_outline,
                  Colors.orange,
                ),
                SizedBox(height: 16),
                _buildStatusCard(
                  'Completed',
                  'Exam cycle has finished.',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                SizedBox(height: 16),
                _buildStatusCard(
                  'Cancelled',
                  'Exam has been officially cancelled.',
                  Icons.cancel_outlined,
                  Colors.red,
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
