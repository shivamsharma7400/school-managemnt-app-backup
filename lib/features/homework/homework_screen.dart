import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/assignment_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/assignment_model.dart';
import 'package:intl/intl.dart';
import '../common/widgets/class_dropdown.dart';

class HomeworkScreen extends StatefulWidget {
  @override
  _HomeworkScreenState createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    // Initialize with user's assigned class, but allow it to be changed
    final authService = Provider.of<AuthService>(context, listen: false);
    _selectedClassId = authService.classId;
  }

  @override
  Widget build(BuildContext context) {
    // If _selectedClassId is somehow null (e.g. fresh login with no class), default to '1' or handle gracefully
    // But typically initState handles it. If user has no class, it might be null initially.
    
    return Scaffold(
      appBar: AppBar(title: Text('Homework')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClassDropdown(
              value: _selectedClassId,
              labelText: "Select Class to View Homework",
              onChanged: (val) {
                setState(() {
                  _selectedClassId = val;
                });
              },
            ),
          ),
          Expanded(
            child: _selectedClassId == null
                ? Center(child: Text("Please select a class"))
                : StreamBuilder(
                    stream: Provider.of<AssignmentService>(context).getAssignmentsForClass(_selectedClassId!), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                
                if (snapshot.hasError) {
                   return Center(child: Text("Error loading homework", style: TextStyle(color: Colors.red)));
                }

                if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                  return _buildEmptyState("No recent homework found.");
                }

                final assignments = snapshot.data as List<Assignment>;
                
                // Group assignments
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final yesterday = today.subtract(Duration(days: 1));
                
                List<Assignment> todayList = [];
                List<Assignment> yesterdayList = [];
                List<Assignment> previousList = [];

                for (var a in assignments) {
                  final aDate = DateTime(a.assignedDate.year, a.assignedDate.month, a.assignedDate.day);
                  if (aDate.isAtSameMomentAs(today)) {
                    todayList.add(a);
                  } else if (aDate.isAtSameMomentAs(yesterday)) {
                    yesterdayList.add(a);
                  } else {
                    previousList.add(a);
                  }
                }

                return ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    if (todayList.isNotEmpty) ...[
                      _buildSectionHeader("Today"),
                      ...todayList.map((a) => _buildAssignmentCard(context, a)),
                    ],
                    if (yesterdayList.isNotEmpty) ...[
                      _buildSectionHeader("Yesterday"),
                      ...yesterdayList.map((a) => _buildAssignmentCard(context, a)),
                    ],
                    if (previousList.isNotEmpty) ...[
                      _buildSectionHeader("Previous"),
                      ...previousList.map((a) => _buildAssignmentCard(context, a)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(
                     color: Theme.of(context).primaryColor.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(
                     assignment.subject, 
                     style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)
                   ),
                ),
                Text(
                    DateFormat('MMM d, h:mm a').format(assignment.assignedDate), 
                    style: TextStyle(color: Colors.grey, fontSize: 12)
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(assignment.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(assignment.description, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
             SizedBox(height: 12),
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 Icon(Icons.event_available, size: 16, color: Colors.red),
                 SizedBox(width: 4),
                 Text(
                   "Due: ${DateFormat('MMM d').format(assignment.dueDate)}", 
                   style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_edu, size: 60, color: Colors.grey.shade300),
        SizedBox(height: 20),
        Text(message, style: TextStyle(color: Colors.grey)),
      ],
    ));
  }
}
