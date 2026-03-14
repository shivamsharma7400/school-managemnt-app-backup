import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import 'package:intl/intl.dart';
import '../../../data/models/leave_request.dart';
import '../../../data/services/leave_service.dart';
import './widgets/leave_a4_paper.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Leave Applications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.black87, Colors.black]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showApplyLeaveForm(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Draft New A4 Application',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text("RECENT APPLICATIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
                Spacer(),
                Icon(Icons.filter_list, size: 16, color: Colors.grey),
              ],
            ),
          ),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu, size: 64, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text('No applications found.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final leaves = snapshot.data!;

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: leaves.length,
                  itemBuilder: (context, index) {
                    final leave = leaves[index];
                    return _buildLeaveListTile(context, leave);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveListTile(BuildContext context, LeaveRequest leave) {
    final statusColor = _getStatusColor(leave.status);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewLeaveA4(context, leave),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Mini A4 Paper Icon
                Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  padding: EdgeInsets.all(4),
                  child: Column(
                    children: List.generate(5, (i) => Container(
                      height: 2,
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 4),
                      color: Colors.grey[200],
                    )),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leave.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    SizedBox(height: 8),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _viewLeaveA4(BuildContext context, LeaveRequest leave) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(20),
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: LeaveA4Paper(leave: leave),
              ),
              SizedBox(height: 20),
              FloatingActionButton.extended(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                onPressed: () => Navigator.pop(context),
                label: Text("Close View"),
                icon: Icon(Icons.close),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showApplyLeaveForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _LeaveA4Editor()),
    );
  }
}

class _LeaveA4Editor extends StatefulWidget {
  @override
  __LeaveA4EditorState createState() => __LeaveA4EditorState();
}

class __LeaveA4EditorState extends State<_LeaveA4Editor> {
  final _reasonController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 1));
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Create a temporary leave request for preview
    final tempLeave = LeaveRequest(
      id: 'preview',
      userId: authService.user?.uid ?? '',
      userName: authService.userName,
      userRole: authService.role ?? 'applicant',
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.isEmpty ? "Start typing your reason here..." : _reasonController.text,
      status: 'pending',
      appliedOn: DateTime.now(),
    );

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text("Draft Application"),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _submitForm,
              child: Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            )
        ],
      ),
      body: Column(
        children: [
          // A4 Preview Section
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Center(
                child: LeaveA4Paper(
                  leave: tempLeave,
                ),
              ),
            ),
          ),
          
          // Form Controls Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: "START DATE",
                        date: _startDate,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _DateTile(
                        label: "END DATE",
                        date: _endDate,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Reason for leave (e.g., Application for urgent work...)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(picked)) _endDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a reason')));
      return;
    }

    setState(() => _isSaving = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final leaveService = Provider.of<LeaveService>(context, listen: false);

    final leave = LeaveRequest(
      id: '',
      userId: authService.user!.uid,
      userName: authService.userName,
      userRole: authService.role ?? 'applicant',
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.trim(),
      status: 'pending',
      appliedOn: DateTime.now(),
    );

    try {
      await leaveService.applyLeave(leave);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application submitted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateTile({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            SizedBox(height: 4),
            Text(DateFormat('dd MMM yyyy').format(date), style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
