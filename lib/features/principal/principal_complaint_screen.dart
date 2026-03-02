import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/data/models/complaint_model.dart';
import 'package:vps/data/services/complaint_service.dart';
import 'package:intl/intl.dart';

class PrincipalComplaintListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final complaintService = Provider.of<ComplaintService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint Box'),
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: complaintService.getPendingComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return Center(child: Text('No pending complaints.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return _ComplaintCard(complaint: complaint);
            },
          );
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;

  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(complaint.userRole.toUpperCase(), style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue),
                ),
                Text(
                  DateFormat('MMM d, y • h:mm a').format(complaint.timestamp),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              complaint.subject,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 4),
            Text(
              'From: ${complaint.userName}',
              style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 12),
            Text(complaint.description),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectDialog(context, complaint),
                  child: Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showApproveDialog(context, complaint),
                  child: Text('Approve'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => _ResponseDialog(
        complaint: complaint,
        isApprove: true,
      ),
    );
  }

  void _showRejectDialog(BuildContext context, ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => _ResponseDialog(
        complaint: complaint,
        isApprove: false,
      ),
    );
  }
}

class _ResponseDialog extends StatefulWidget {
  final ComplaintModel complaint;
  final bool isApprove;

  const _ResponseDialog({required this.complaint, required this.isApprove});

  @override
  _ResponseDialogState createState() => _ResponseDialogState();
}

class _ResponseDialogState extends State<_ResponseDialog> {
  final _responseController = TextEditingController();
  bool _isGenerating = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _generateAIResponse(); // Auto-generate response when dialog opens
  }

  Future<void> _generateAIResponse() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final complaintService = Provider.of<ComplaintService>(context, listen: false);
      final response = await complaintService.generateResponseWithAI(
        widget.complaint.description,
        widget.isApprove,
      );

      if (response != null && mounted) {
        _responseController.text = response;
      }
    } catch (e) {
      // Handle error cleanly
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final complaintService = Provider.of<ComplaintService>(context, listen: false);
      if (widget.isApprove) {
        await complaintService.approveComplaint(widget.complaint.id, _responseController.text);
      } else {
        await complaintService.rejectComplaint(widget.complaint.id, _responseController.text);
      }
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isApprove ? 'Complaint Approved' : 'Complaint Rejected')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
    return AlertDialog(
      title: Text(widget.isApprove ? 'Approve Complaint' : 'Reject Complaint'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Generating AI Response...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            TextField(
              controller: _responseController,
              decoration: InputDecoration(
                labelText: 'Response',
                hintText: 'Enter your response here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 TextButton.icon(
                  onPressed: _isGenerating ? null : _generateAIResponse,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Regenerate AI'),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitResponse,
          child: _isSubmitting 
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Send Response'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isApprove ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
