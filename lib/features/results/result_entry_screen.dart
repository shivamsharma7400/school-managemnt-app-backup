import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/result_service.dart';
import '../../data/models/result_model.dart';
import '../../data/services/user_service.dart';
import '../../data/services/class_service.dart';
import '../../data/models/class_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/scheduled_exam_model.dart';

class ResultEntryScreen extends StatefulWidget {
  const ResultEntryScreen({super.key});

  @override
  _ResultEntryScreenState createState() => _ResultEntryScreenState();
}

class _ResultEntryScreenState extends State<ResultEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedClassId;
  String? _selectedStudentId;
  ScheduledExam? _selectedExam;
  
  final TextEditingController _rollNumberController = TextEditingController(); 

  // Dynamic Subjects List
  // List of Maps: { 'name': Controller, 'obtained': Controller, 'full': Controller }
  final List<Map<String, TextEditingController>> _subjectControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default one subject row
    _addSubjectRow();
  }

  void _addSubjectRow({String name = '', String full = '100'}) {
    setState(() {
      _subjectControllers.add({
        'name': TextEditingController(text: name),
        'obtained': TextEditingController(),
        'full': TextEditingController(text: full),
      });
    });
  }

  void _removeSubjectRow(int index) {
    setState(() {
      _subjectControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<AuthService>(context).role;
    final resultService = Provider.of<ResultService>(context);
    
    // Authorization Check
    if (userRole != 'management' && userRole != 'teacher') {
      return Scaffold(
        appBar: AppBar(title: Text('Access Denied')),
        body: Center(child: Text("Only Management and Teachers can enter exam results.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Enter Exam Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildClassDropdown(),
               SizedBox(height: 16),
               if (_selectedClassId != null) _buildStudentDropdown(),
               SizedBox(height: 16),
               
               TextFormField(
                 controller: _rollNumberController,
                 decoration: InputDecoration(labelText: 'Roll Number (Mandatory)', border: OutlineInputBorder()),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               SizedBox(height: 16),
               
               _buildExamDropdown(resultService),
               SizedBox(height: 16),
               
               SizedBox(height: 24),
               Text("Subjects", style: Theme.of(context).textTheme.titleMedium),
               Divider(),
               
               ..._subjectControllers.asMap().entries.map((entry) {
                 int index = entry.key;
                 var controllers = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: controllers['name'],
                            enabled: false, // Read-only from routine
                            decoration: InputDecoration(
                              labelText: 'Subject', 
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              fillColor: Colors.grey[100],
                              filled: true,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: controllers['obtained'],
                            decoration: InputDecoration(labelText: 'Obtained', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Req' : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: controllers['full'],
                            enabled: false, // Read-only from routine
                            decoration: InputDecoration(
                              labelText: 'Full', 
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              fillColor: Colors.grey[100],
                              filled: true,
                            ),
                          ),
                        ),
                        // Removed delete button to prevent accidental removal of routine subjects
                      ],
                    ),
                  );
               }),

                // No more manual subject adding as it's fetched from routine

               SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _submitResult,
                   style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                   child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Save & Publish Result'),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return StreamBuilder<List<ClassModel>>(
      stream: Provider.of<ClassService>(context).getAllClasses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return DropdownButtonFormField<String>(
          initialValue: _selectedClassId,
          decoration: InputDecoration(labelText: 'Select Class', border: OutlineInputBorder()),
          items: snapshot.data!.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
          onChanged: (val) => setState(() {
            _selectedClassId = val;
            _selectedStudentId = null; // Reset student
          }),
        );
      },
    );
  }

  Widget _buildStudentDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context).getStudentsByClass(_selectedClassId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Text("No students in this class");
        
        final students = snapshot.data!;

        return DropdownButtonFormField<String>(
          initialValue: _selectedStudentId,
          decoration: InputDecoration(labelText: 'Select Student', border: OutlineInputBorder()),
          items: students.map((s) {
            return DropdownMenuItem(
              value: s['id'] as String,
              child: Text("${s['name']} (Adm: ${s['admNo'] ?? 'N/A'})"),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedStudentId = val;
              // Auto-fill Roll Number from student's customData
              final student = students.firstWhere((s) => s['id'] == val);
              final dynamic rollNo = (student['customData'] as Map<String, dynamic>?)?['Roll.no'];
              _rollNumberController.text = rollNo?.toString() ?? 'N/A';
            });
          },
          validator: (v) => v == null ? 'Please select a student' : null,
        );
      },
    );
  }

  Widget _buildExamDropdown(ResultService resultService) {
    return StreamBuilder<List<ScheduledExam>>(
      stream: resultService.getScheduledExams(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final exams = snapshot.data!;
        if (exams.isEmpty) return const Text("No scheduled exams found. Please setup exams in Principal Dashboard.");
        
        return DropdownButtonFormField<ScheduledExam>(
          initialValue: _selectedExam,
          decoration: const InputDecoration(labelText: 'Select Exam', border: OutlineInputBorder()),
          items: exams.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedExam = val;
              // Auto-populate subjects from routine
              _subjectControllers.clear();
              if (val?.routineConfig != null) {
                final subjects = val!.routineConfig!['subjects'] as List? ?? [];
                for (var s in subjects) {
                  if (s is String) {
                    _addSubjectRow(name: s, full: '100');
                  } else if (s is Map) {
                    _addSubjectRow(
                      name: s['name'] ?? 'Unknown',
                      full: (s['fullMarks'] ?? 100).toString(),
                    );
                  }
                }
              }
            });
          },
          validator: (v) => v == null ? 'Please select an exam' : null,
        );
      },
    );
  }

  void _submitResult() async {
    if (_formKey.currentState!.validate() && _selectedStudentId != null && _selectedExam != null) {
      if (_subjectControllers.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an exam with a routine setup first.')));
         return;
      }

      setState(() => _isLoading = true);
      final resultService = Provider.of<ResultService>(context, listen: false);

      // Collect Subjects
      List<Map<String, dynamic>> subjectsData = [];
      Map<String, String> syncMarks = {};
      double totalObtained = 0;
      double totalFull = 0;
      
      for (var controllers in _subjectControllers) {
        String name = controllers['name']!.text.trim();
        String obtainedStr = controllers['obtained']!.text.trim();
        double obtained = double.tryParse(obtainedStr) ?? 0;
        double full = double.tryParse(controllers['full']!.text) ?? 100;
        
        subjectsData.add({
          'subject': name,
          'obtained': obtained,
          'full': full,
        });
        syncMarks[name] = obtainedStr;
        totalObtained += obtained;
        totalFull += full;
      }

      // Grade Calculation
      double percentage = (totalFull > 0) ? (totalObtained / totalFull) * 100 : 0;
      String grade = 'F';
      if (percentage >= 90) {
        grade = 'A+';
      } else if (percentage >= 80) grade = 'A';
      else if (percentage >= 70) grade = 'B';
      else if (percentage >= 60) grade = 'C';
      else if (percentage >= 40) grade = 'D';

      final result = ExamResult(
        id: '', 
        studentId: _selectedStudentId!, 
        examName: _selectedExam!.name, 
        subjects: subjectsData, 
        totalObtainedMarks: totalObtained, 
        totalFullMarks: totalFull, 
        rollNumber: _rollNumberController.text.trim(),
        grade: grade
      );

      // 1. Add to individual results
      await resultService.addResult(result);
      
      // 2. Sync to Principal's Result Sheet
      await resultService.syncResultToSheet(
        _selectedExam!.id, 
        _selectedClassId!, 
        _selectedStudentId!, 
        syncMarks
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Result Published & Synced Successfully!')));
      }
    }
  }
}
