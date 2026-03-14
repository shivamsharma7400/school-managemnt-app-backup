import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/leave_request.dart';
import '../../../data/services/leave_service.dart';
import '../../common/leave/widgets/leave_a4_paper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveApprovalScreen extends StatelessWidget {
  const LeaveApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Pending Leave Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<LeaveRequest>>(
        stream: Provider.of<LeaveService>(context).getPendingLeaves(),
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
                  Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('All caught up! No pending requests.', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final leaves = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => _openApprovalA4View(context, leave),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Text(leave.userName[0].toUpperCase(), style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(leave.userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                "Reason: ${leave.reason}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}",
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(leave.userRole.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(height: 8),
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openApprovalA4View(BuildContext context, LeaveRequest leave) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ApprovalA4Dialog(leave: leave),
    );
  }
}

class _ApprovalA4Dialog extends StatefulWidget {
  final LeaveRequest leave;
  const _ApprovalA4Dialog({required this.leave});

  @override
  State<_ApprovalA4Dialog> createState() => _ApprovalA4DialogState();
}

class _ApprovalA4DialogState extends State<_ApprovalA4Dialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                   constraints: BoxConstraints(maxWidth: 500),
                   child: Container(
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(8),
                       color: Colors.white,
                     ),
                     child: LeaveA4Paper(leave: widget.leave),
                   ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      label: "Reject",
                      icon: Icons.close,
                      color: Colors.red,
                      onPressed: () => _handleUpdate(context, 'rejected'),
                    ),
                    SizedBox(width: 20),
                    _buildActionButton(
                      label: "Approve with Sign & Stamp",
                      icon: Icons.verified_user,
                      color: Colors.green,
                      isPrimary: true,
                      onPressed: () => _handleUpdate(context, 'approved'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  void _handleUpdate(BuildContext context, String status) async {
    setState(() => _isProcessing = true);

    try {
      String? signUrl;
      String? stampUrl;

      if (status == 'approved') {
        // Fetch official assets from settings
        final configDoc = await FirebaseFirestore.instance.collection('settings').doc('config').get();
        final configData = configDoc.data() ?? {};
        
        // Use provided URLs or placeholders for demo if missing
        signUrl = configData['principalSignatureUrl'] ?? 'https://firebasestorage.googleapis.com/v0/b/vps-project-1122.appspot.com/o/demo%2Fsignature.png?alt=media';
        stampUrl = configData['schoolStampUrl'] ?? 'https://firebasestorage.googleapis.com/v0/b/vps-project-1122.appspot.com/o/demo%2Fstamp.png?alt=media';
      }

      await Provider.of<LeaveService>(context, listen: false)
          .updateLeaveStatus(widget.leave.id, status, signatureUrl: signUrl, stampUrl: stampUrl);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave request $status successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
