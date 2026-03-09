import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';

class PTMHandlingScreen extends StatefulWidget {
  final ScheduledExam exam;

  const PTMHandlingScreen({super.key, required this.exam});

  @override
  _PTMHandlingScreenState createState() => _PTMHandlingScreenState();
}

class _PTMHandlingScreenState extends State<PTMHandlingScreen> {
  DateTime? _meetingDate;
  TimeOfDay _meetingTime = TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _agendaController = TextEditingController(text: 'Discussion of Term Exam Results');

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 60)),
    );
    if (picked != null) setState(() => _meetingDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _meetingTime,
    );
    if (picked != null) setState(() => _meetingTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('PTM Handling', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Parent-Teacher Meeting',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Schedule a PTM for parents to discuss the results of ${widget.exam.name}.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            
            // Date Selection
            _buildSelectionTile(
              'Meeting Date',
              _meetingDate == null ? 'Not Selected' : DateFormat('dd MMM yyyy').format(_meetingDate!),
              Icons.calendar_today,
              _selectDate,
            ),
            SizedBox(height: 16),
            
            // Time Selection
            _buildSelectionTile(
              'Meeting Time',
              _meetingTime.format(context),
              Icons.access_time,
              _selectTime,
            ),
            SizedBox(height: 24),
            
            // Agenda
            Text('Meeting Agenda', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: _agendaController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              ),
            ),
            SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_meetingDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a date')));
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PTM Scheduled Successfully')));
                  Navigator.pop(context);
                },
                icon: Icon(Icons.send),
                label: Text('Schedule and Notify Parents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.modernPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile(String label, String value, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.modernPrimary),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        subtitle: Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
