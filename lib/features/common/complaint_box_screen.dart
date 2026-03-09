import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/data/services/auth_service.dart';
import 'package:vps/data/services/complaint_service.dart';
import 'package:vps/data/models/complaint_model.dart';
import 'package:vps/data/services/user_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ComplaintBoxScreen extends StatefulWidget {
  const ComplaintBoxScreen({super.key});

  @override
  _ComplaintBoxScreenState createState() => _ComplaintBoxScreenState();
}

class _ComplaintBoxScreenState extends State<ComplaintBoxScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isRewriting = false;
  bool _isSubmitting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _rewriteWithAI() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter some text to rewrite.')),
      );
      return;
    }

    setState(() {
      _isRewriting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final complaintService = Provider.of<ComplaintService>(context, listen: false);
      final user = authService.user;
      final userService = Provider.of<UserService>(context, listen: false);
      String userName = 'User';
      String userRole = 'Student';

      Map<String, dynamic>? fullUserData;
      if (user != null) {
        fullUserData = await userService.getUserData(user.uid);
        userName = fullUserData?['name'] ?? 'User';
        userRole = authService.role ?? 'Student';
      }

      final rewrittenText = await complaintService.rewriteComplaintWithAI(
        _descriptionController.text, 
        userName, 
        userRole,
        userDetails: fullUserData,
      );
      
      if (rewrittenText != null && mounted) {
        _descriptionController.text = rewrittenText;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rewrite: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRewriting = false;
        });
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);

      final user = authService.user;
      
      if (user != null) {
        final userData = await userService.getUserData(user.uid);
        final userName = userData?['name'] ?? 'Unknown User';
        final userRole = authService.role ?? 'Unknown Role';

        final complaint = ComplaintModel(
          id: Uuid().v4(),
          userId: user.uid,
          userName: userName,
          userRole: userRole,
          subject: _subjectController.text,
          description: _descriptionController.text,
          status: 'pending',
          timestamp: DateTime.now(),
        );

        final complaintService = Provider.of<ComplaintService>(context, listen: false);
        await complaintService.submitComplaint(complaint);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Complaint submitted successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _subjectController.clear();
          _descriptionController.clear();
          _tabController.animateTo(1); // Switch to history tab
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit complaint: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Complaint Box', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: [
            Tab(icon: Icon(Icons.edit_note), text: 'New Complaint'),
            Tab(icon: Icon(Icons.history), text: 'My Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComplaintForm(),
          _buildComplaintHistory(),
        ],
      ),
    );
  }

  Widget _buildComplaintForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.amber, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'We value your voice.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Describe your issue clearly. Use AI to polish your message.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.title, color: Colors.purple),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a subject' : null,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 8,
                      validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.purple.shade200, Colors.deepPurple.shade200]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isRewriting ? null : _rewriteWithAI,
                          icon: _isRewriting 
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                              : Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          label: Text(_isRewriting ? 'Rewriting...' : 'Rewrite with AI'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitComplaint,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _isSubmitting 
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Submit Complaint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintHistory() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final complaintService = Provider.of<ComplaintService>(context, listen: false);
    final user = authService.user;

    if (user == null) return Center(child: Text('Please log in to view history'));

    return StreamBuilder<List<ComplaintModel>>(
      stream: complaintService.getUserComplaints(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Error loading complaints'),
            ],
          ));
        }
        
        final complaints = snapshot.data ?? [];
        if (complaints.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text('No complaints yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
              Text('Your submitted complaints will appear here', style: TextStyle(color: Colors.grey[400])),
            ],
          ));
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: complaints.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: Icon(Icons.description, color: Colors.purple),
                  ),
                  title: Text(
                    complaint.subject, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('MMM d, y • h:mm a').format(complaint.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  trailing: _buildStatusChip(complaint.status),
                  children: [
                    Divider(color: Colors.grey[200]),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2)),
                          SizedBox(height: 8),
                          Text(complaint.description, style: TextStyle(fontSize: 15, height: 1.4)),
                        ],
                      ),
                    ),
                    if (complaint.response != null) ...[
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(complaint.status).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(complaint.status).withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.admin_panel_settings, size: 18, color: _getStatusColor(complaint.status)),
                                SizedBox(width: 8),
                                Text('PRINCIPAL RESPONSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(complaint.status), letterSpacing: 1.2)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(complaint.response!, style: TextStyle(fontSize: 15, height: 1.4, fontStyle: FontStyle.italic, color: Colors.grey[800])),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    IconData icon;
    
    switch (status) {
      case 'approved': icon = Icons.check_circle; break;
      case 'rejected': icon = Icons.cancel; break;
      default: icon = Icons.hourglass_top;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
