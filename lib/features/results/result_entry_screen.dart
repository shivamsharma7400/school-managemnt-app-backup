import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/result_service.dart';
import '../../data/models/result_model.dart';
import '../../data/services/user_service.dart';
import '../../data/services/class_service.dart';
import '../../data/models/class_model.dart';
import '../../data/services/auth_service.dart';

class ResultEntryScreen extends StatefulWidget {
  @override
  _ResultEntryScreenState createState() => _ResultEntryScreenState();
}

class _ResultEntryScreenState extends State<ResultEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedClassId;
  String? _selectedStudentId;
  
  final TextEditingController _examNameController = TextEditingController();
  final TextEditingController _grandTotalController = TextEditingController(); // Overall full marks
  final TextEditingController _rollNumberController = TextEditingController(); 

  // Dynamic Subjects List
  // List of Maps: { 'name': Controller, 'obtained': Controller, 'full': Controller }
  List<Map<String, TextEditingController>> _subjectControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default one subject row
    _addSubjectRow();
  }

  void _addSubjectRow() {
    setState(() {
      _subjectControllers.add({
        'name': TextEditingController(),
        'obtained': TextEditingController(),
        'full': TextEditingController(text: '100'), // Default 100
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
               TextFormField(
                 controller: _examNameController,
                 decoration: InputDecoration(labelText: 'Exam Name (e.g. Mid-Term 2026)', border: OutlineInputBorder()),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               SizedBox(height: 16),
               TextFormField(
                 controller: _grandTotalController,
                 decoration: InputDecoration(labelText: 'Grand Total Full Marks (e.g. 500)', border: OutlineInputBorder()),
                 keyboardType: TextInputType.number,
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               
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
                           decoration: InputDecoration(labelText: 'Subject Name', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                           validator: (v) => v!.isEmpty ? 'Required' : null,
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
                           decoration: InputDecoration(labelText: 'Full', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                           keyboardType: TextInputType.number,
                           validator: (v) => v!.isEmpty ? 'Req' : null,
                         ),
                       ),
                       IconButton(
                         icon: Icon(Icons.delete, color: Colors.red),
                         onPressed: () => _removeSubjectRow(index),
                       )
                     ],
                   ),
                 );
               }).toList(),

               TextButton.icon(
                 icon: Icon(Icons.add),
                 label: Text("Add Subject"),
                 onPressed: _addSubjectRow,
               ),

               SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _submitResult,
                   child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Save & Publish Result'),
                   style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
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
          value: _selectedClassId,
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
        
        return DropdownButtonFormField<String>(
          value: _selectedStudentId,
          decoration: InputDecoration(labelText: 'Select Student', border: OutlineInputBorder()),
          items: snapshot.data!.map((s) {
            return DropdownMenuItem(
              value: s['id'] as String,
              child: Text("${s['name']} (${s['email']})"),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedStudentId = val),
          validator: (v) => v == null ? 'Please select a student' : null,
        );
      },
    );
  }

  void _submitResult() async {
    if (_formKey.currentState!.validate() && _selectedStudentId != null) {
      if (_subjectControllers.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add at least one subject')));
         return;
      }

      setState(() => _isLoading = true);

      // Collect Subjects
      List<Map<String, dynamic>> subjectsData = [];
      double totalObtained = 0;
      
      for (var controllers in _subjectControllers) {
        String name = controllers['name']!.text.trim();
        double obtained = double.tryParse(controllers['obtained']!.text) ?? 0;
        double full = double.tryParse(controllers['full']!.text) ?? 100;
        
        subjectsData.add({
          'subject': name,
          'obtained': obtained,
          'full': full,
        });
        totalObtained += obtained;
      }

      double totalFull = double.tryParse(_grandTotalController.text) ?? 0;

      // Grade Calculation Logic (Percentage based)
      double percentage = (totalFull > 0) ? (totalObtained / totalFull) * 100 : 0;
      String grade = 'F';
      if (percentage >= 90) grade = 'A+';
      else if (percentage >= 80) grade = 'A';
      else if (percentage >= 70) grade = 'B';
      else if (percentage >= 60) grade = 'C';
      else if (percentage >= 40) grade = 'D';

      final result = ExamResult(
        id: '', 
        studentId: _selectedStudentId!, 
        examName: _examNameController.text.trim(), 
        subjects: subjectsData, 
        totalObtainedMarks: totalObtained, 
        totalFullMarks: totalFull, 
        rollNumber: _rollNumberController.text.trim(),
        grade: grade
      );

      await Provider.of<ResultService>(context, listen: false).addResult(result);
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }
}
