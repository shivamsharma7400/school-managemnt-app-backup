import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/leave_request.dart';
import '../../../data/services/leave_service.dart';

class LeaveApprovalScreen extends StatelessWidget {
  const LeaveApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leave Requests')),
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
            return Center(child: Text('No pending leave requests.'));
          }

          final leaves = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return Card(
                 elevation: 3,
                 margin: EdgeInsets.only(bottom: 12),
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Text(leave.userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Chip(label: Text(leave.userRole.toUpperCase(), style: TextStyle(fontSize: 10))),
                         ],
                       ),
                       SizedBox(height: 8),
                       Text("Reason: ${leave.reason}", style: TextStyle(fontSize: 16)),
                       SizedBox(height: 8),
                       Text(
                         "From: ${DateFormat('dd MMM').format(leave.startDate)} To: ${DateFormat('dd MMM yyyy').format(leave.endDate)}",
                         style: TextStyle(color: Colors.grey[700]),
                       ),
                       SizedBox(height: 16),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                           OutlinedButton(
                             onPressed: () => _updateStatus(context, leave.id, 'rejected'),
                             style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                             child: Text('Reject'),
                           ),
                           SizedBox(width: 12),
                           ElevatedButton(
                             onPressed: () => _updateStatus(context, leave.id, 'approved'),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                             child: Text('Approve'),
                           ),
                         ],
                       )
                     ],
                   ),
                 ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(BuildContext context, String leaveId, String status) {
    Provider.of<LeaveService>(context, listen: false)
        .updateLeaveStatus(leaveId, status)
        .then((_) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave request $status')));
        })
        .catchError((e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        });
  }
}
