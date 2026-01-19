import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/assignment_service.dart';
import '../../data/services/class_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/class_model.dart';
import '../../data/models/assignment_model.dart';
import 'package:intl/intl.dart';
import '../../data/services/notification_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  @override
  _CreateAssignmentScreenState createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClassId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(Duration(days: 1));
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Assignment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildClassDropdown(),
               SizedBox(height: 16),
               TextFormField(
                 controller: _titleController,
                 decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               SizedBox(height: 16),
               TextFormField(
                 controller: _subjectController,
                 decoration: InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               SizedBox(height: 16),
               TextFormField(
                 controller: _descController,
                 decoration: InputDecoration(labelText: 'Description / Instructions', border: OutlineInputBorder()),
                 maxLines: 3,
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               SizedBox(height: 16),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: Text("Due Date: ${DateFormat('EEE, d MMM y').format(_dueDate)}"),
                 trailing: Icon(Icons.calendar_today),
                 onTap: _pickDate,
               ),
               Spacer(),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _submit,
                   child: _isLoading ? CircularProgressIndicator() : Text('Post Assignment'),
                   style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
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
      stream: Provider.of<ClassService>(context).getAllClasses(), // Should filter by teacher
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return DropdownButtonFormField<String>(
          value: _selectedClassId,
          decoration: InputDecoration(labelText: 'Select Class', border: OutlineInputBorder()),
          items: snapshot.data!.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
          onChanged: (val) => setState(() => _selectedClassId = val),
          validator: (v) => v == null ? 'Please select a class' : null,
        );
      },
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final teacherId = Provider.of<AuthService>(context, listen: false).user?.uid ?? '';
      
      // DEBUG: Show selected class ID in snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("DEBUG: Posting to Class ID: '$_selectedClassId'"),
        duration: Duration(seconds: 5),
      ));

      final assignment = Assignment(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        subject: _subjectController.text.trim(),
        classId: _selectedClassId!,
        dueDate: _dueDate,
        assignedDate: DateTime.now(),
        teacherId: teacherId,
      );

      await Provider.of<AssignmentService>(context, listen: false).addAssignment(assignment);
      
      // Trigger Notification
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      notificationService.sendNotificationToClass(
        _selectedClassId!,
        'New Assignment: ${_subjectController.text}',
        '${_titleController.text} due on ${DateFormat('MMM d').format(_dueDate)}'
      );

      // Removed Navigator.pop to let user see snackbar (or wait a bit)
       await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context);
    }
  }
}
