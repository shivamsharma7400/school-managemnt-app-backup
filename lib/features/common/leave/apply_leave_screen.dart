import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/ai_service.dart';
import 'package:intl/intl.dart';
import '../../../data/models/leave_request.dart';
import '../../../data/services/leave_service.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  _ApplyLeaveScreenState createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    final userId = user?.uid;

    if (userId == null) return Scaffold(body: Center(child: Text("User not logged in")));

    return Scaffold(
      appBar: AppBar(title: Text('Apply Leave')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Create New Application'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
                onPressed: () => _showApplyLeaveForm(context),
              ),
            ),
          ),
          Divider(),
          Expanded(
            child: StreamBuilder<List<LeaveRequest>>(
              stream: Provider.of<LeaveService>(context).getMyLeaves(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No leave applications found.'));
                }

                final leaves = snapshot.data!;

                  return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: leaves.length,
                  itemBuilder: (context, index) {
                    final leave = leaves[index];
                    final statusColor = _getStatusColor(leave.status);
                    
                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(leave.reason, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      '${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            color: statusColor,
                            child: Row(
                              children: [
                                Text(
                                  "Status:", 
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  leave.status.toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade100;
      case 'rejected':
        return Colors.red.shade100;
      case 'pending':
      default:
        return Colors.grey.shade100;
    }
  }

  void _showApplyLeaveForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _LeaveForm(),
      ),
    );
  }
}

class _LeaveForm extends StatefulWidget {
  @override
  __LeaveFormState createState() => __LeaveFormState();
}

class __LeaveFormState extends State<_LeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Leave Request', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(labelText: 'Reason'),
              maxLines: 3,
              validator: (val) => val!.isEmpty ? 'Enter reason' : null,
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(Icons.auto_awesome, color: Colors.purple),
                label: Text('Rewrite with AI', style: TextStyle(color: Colors.purple)),
                onPressed: () async {
                  if (_reasonController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a short reason first.')));
                    return;
                  }
                  if (_startDate == null || _endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select start and end dates first.')));
                    return;
                  }

                  final authService = Provider.of<AuthService>(context, listen: false);
                  final aiService = Provider.of<AIService>(context, listen: false);

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI is writing your application...')));

                  final formalLetter = await aiService.generateLeaveApplication(
                    reason: _reasonController.text,
                    startDate: DateFormat('dd MMM yyyy').format(_startDate!),
                    endDate: DateFormat('dd MMM yyyy').format(_endDate!),
                    name: authService.userName,
                    role: authService.role ?? 'Student',
                    className: authService.classId,
                  );

                  if (formalLetter != null) {
                    _reasonController.text = formalLetter;
                  }
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text(_startDate == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(_startDate!)),
                    onPressed: () => _pickDate(context, true),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text(_endDate == null ? 'End Date' : DateFormat('dd MMM yyyy').format(_endDate!)),
                    onPressed: () => _pickDate(context, false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit Request'),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Cannot apply for past leaves usually
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Auto set end date if null or before start
          if (_endDate == null || _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select valid dates')));
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('End date cannot be before start date')));
         return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final leaveService = Provider.of<LeaveService>(context, listen: false);

      final user = authService.user;
      final leave = LeaveRequest(
        id: '', // Generated by Firestore
        userId: user!.uid,
        userName: authService.userName, // Helper in AuthService
        userRole: 'applicant', // Ideally fetch role. Simplified for now. Principal sees name.
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reasonController.text.trim(),
        status: 'pending',
        appliedOn: DateTime.now(),
      );

      try {
        await leaveService.applyLeave(leave);
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave request submitted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    }
  }
}
