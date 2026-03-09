import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';
import '../../data/services/user_service.dart';

class TeachersSetupScreen extends StatefulWidget {
  final ScheduledExam exam;

  const TeachersSetupScreen({super.key, required this.exam});

  @override
  _TeachersSetupScreenState createState() => _TeachersSetupScreenState();
}

class _TeachersSetupScreenState extends State<TeachersSetupScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, Map<String, dynamic>> _workloadData = {};
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load teachers from Firestore via UserService stream (fetching once for simplicity in setup)
      final userService = Provider.of<UserService>(context, listen: false);
      final teachersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();
      
      _teachers = teachersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load existing workload from exam doc
      final examDoc = await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .get();
      
      if (examDoc.exists && examDoc.data()!.containsKey('teacher_workload')) {
        final savedData = examDoc.data()!['teacher_workload'] as Map<String, dynamic>;
        _workloadData = savedData.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      } else {
        // Initialize empty workload for all teachers
        for (var t in _teachers) {
          final id = t['id'];
          _workloadData[id] = {
            'name': t['name'] ?? 'Unknown',
            'paper': '',
            'class': '',
            'target': '',
            'other': '',
          };
        }
      }
    } catch (e) {
      print('Error loading teacher setup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .update({
        'teacher_workload': _workloadData,
      });
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workload distribution saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
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
        title: Text('Teachers Setup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit_note, size: 28),
              onPressed: () => _isEditing ? _saveData() : setState(() => _isEditing = true),
              color: _isEditing ? Colors.green : null,
              tooltip: _isEditing ? 'Save Changes' : 'Edit Workload',
            ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),
                  Center(child: _buildWorkloadTable()),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      color: AppColors.modernPrimary.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.modernPrimary, shape: BoxShape.circle),
              child: Icon(Icons.assignment_ind, color: Colors.white, size: 30),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workload Distribution',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Exam: ${widget.exam.name} • Session: 2025-26',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (!_isEditing)
              ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: Icon(Icons.edit, size: 18),
                label: Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.modernPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkloadTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Container(
                color: AppColors.modernPrimary,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    _buildHeaderCell('Teacher\'s Name', 180),
                    _buildHeaderCell('Paper Distribution', 160),
                    _buildHeaderCell('Class Distribution', 160),
                    _buildHeaderCell('Target Time', 160),
                    _buildHeaderCell('Other Work', 260),
                  ],
                ),
              ),
              // Data Rows
              ..._teachers.map((teacher) {
                final id = teacher['id']!;
                final data = _workloadData[id] ?? {};
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildDataCell(teacher['name'] ?? 'N/A', 180, isName: true),
                      _buildEditCell(id, 'paper', data['paper'] ?? '', 160),
                      _buildEditCell(id, 'class', data['class'] ?? '', 160),
                      _buildEditCell(id, 'target', data['target'] ?? '', 160),
                      _buildEditCell(id, 'other', data['other'] ?? '', 260),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool isName = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontWeight: isName ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEditCell(String teacherId, String field, String value, double width) {
    if (!_isEditing) {
      return SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(
            value.isEmpty ? '-' : value,
            softWrap: true,
            style: TextStyle(
              color: value.isEmpty ? Colors.grey : Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: TextField(
          onChanged: (val) => _workloadData[teacherId]![field] = val,
          controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
          maxLines: null,
          minLines: 1,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
