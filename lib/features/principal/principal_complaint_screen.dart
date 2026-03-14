import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/data/models/complaint_model.dart';
import 'package:vps/data/services/complaint_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vps/core/constants/app_constants.dart';

class PrincipalComplaintListScreen extends StatelessWidget {
  const PrincipalComplaintListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Complaint Box', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'History'),
            ],
            indicatorColor: AppColors.modernPrimary,
            labelColor: AppColors.modernPrimary,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            _ComplaintList(isHistory: false),
            _ComplaintList(isHistory: true),
          ],
        ),
      ),
    );
  }
}

class _ComplaintList extends StatelessWidget {
  final bool isHistory;

  const _ComplaintList({required this.isHistory});

  @override
  Widget build(BuildContext context) {
    final complaintService = Provider.of<ComplaintService>(context);

    return StreamBuilder<List<ComplaintModel>>(
      stream: isHistory ? complaintService.getProcessedComplaints() : complaintService.getPendingComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isHistory ? Icons.history : Icons.inbox, size: 64, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  isHistory ? 'No complaint history found.' : 'All clear! No pending complaints.',
                  style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            return _ComplaintCard(complaint: complaint, isHistory: isHistory);
          },
        );
      },
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isHistory;

  const _ComplaintCard({required this.complaint, required this.isHistory});

  @override
  Widget build(BuildContext context) {
    final bool isApproved = complaint.status == 'approved';
    final Color statusColor = isHistory 
        ? (isApproved ? Colors.green : Colors.red)
        : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  complaint.userRole.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              if (isHistory) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    complaint.status.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            DateFormat('MMM d, h:mm a').format(complaint.timestamp),
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        complaint.subject,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'From: ${complaint.userName}',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600], 
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        complaint.description,
                        style: GoogleFonts.inter(height: 1.5, color: Colors.black87),
                      ),
                      if (isHistory && complaint.response != null) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Text(
                                    'Principal\'s Response:',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                complaint.response!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isHistory) ...[
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showRejectDialog(context, complaint),
                              icon: Icon(Icons.close, size: 18),
                              label: Text('Reject'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showApproveDialog(context, complaint),
                              icon: Icon(Icons.check, size: 18),
                              label: Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, 
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isApprove ? 'Complaint Approved Successfully' : 'Complaint Rejected Successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: widget.isApprove ? Colors.green : Colors.red,
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isApprove ? 'Submit Approval' : 'Submit Rejection',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _responseController,
              decoration: InputDecoration(
                labelText: 'Response',
                labelStyle: GoogleFonts.outfit(fontSize: 14),
                hintText: 'Enter your final decision or reason...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.modernPrimary),
                ),
              ),
              maxLines: 6,
              style: GoogleFonts.inter(fontSize: 14),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitResponse,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isApprove ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSubmitting 
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Confirm Action', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
