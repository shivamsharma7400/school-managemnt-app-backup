import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/features/attendance/mark_attendance_screen.dart';
import 'package:vps/features/common/routine_view_screen.dart';

import 'package:vps/features/homework/create_assignment_screen.dart';
import 'package:vps/features/teacher/student_search_screen.dart';
import 'package:vps/data/services/auth_service.dart';
import 'package:vps/features/notification/notification_screen.dart';
import 'package:vps/features/fees/staff_salary_view_screen.dart';
import 'package:vps/features/attendance/attendance_view_screen.dart';
import 'package:vps/features/communication/announcement_screen.dart';
import 'package:vps/features/common/leave/apply_leave_screen.dart';
import 'package:vps/features/teacher/test/create_test_screen.dart';
import 'package:vps/features/teacher/classes/live_class_setup_screen.dart';
import 'package:vps/features/common/widgets/notification_badge_wrapper.dart';
import 'package:vps/features/common/widgets/dashboard_profile_card.dart';

import 'package:vps/features/results/result_entry_screen.dart';
import 'package:vps/features/common/complaint_box_screen.dart';
import 'package:vps/data/services/class_service.dart';
import 'package:vps/data/models/class_model.dart';
import 'package:vps/features/teacher/class_students_screen.dart';
import 'package:vps/features/teacher/syllabus_selection_screen.dart';


class TeacherDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        actions: [
          NotificationBadgeWrapper(
            child: Icon(Icons.notifications),
          ),
          IconButton(icon: Icon(Icons.logout), onPressed: () => authService.signOut()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             DashboardProfileCard(),
            SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 5;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 3;
                  }

                  return StreamBuilder<List<ClassModel>>(
                    stream: Provider.of<ClassService>(context, listen: false).getAllClasses(),
                    builder: (context, classSnapshot) {
                      final classes = classSnapshot.data ?? [];
                      final user = Provider.of<AuthService>(context).user;
                      final assignedClass = classes.firstWhere(
                        (c) => c.teacherId == user?.uid,
                        orElse: () => ClassModel(id: '', name: 'None', teacherId: ''),
                      );

                      final cards = [
                        if (assignedClass.id.isNotEmpty)
                          _buildModuleCard(context, 'Class Details', Icons.groups, Colors.indigo, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ClassStudentsScreen(assignedClass: assignedClass)));
                          }),
                        _buildModuleCard(context, 'Attendance', Icons.fact_check, Colors.blue, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MarkAttendanceScreen()));
                        }),
                        _buildModuleCard(context, 'Homework', Icons.assignment, Colors.orange, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentScreen()));
                        }),
                        _buildModuleCard(context, 'Announcements', Icons.campaign, Colors.red, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen()));
                        }),
                        _buildModuleCard(context, 'Write to Student', Icons.message, Colors.purple, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StudentSearchScreen()));
                        }),
                        _buildModuleCard(context, 'Salary/Payment', Icons.attach_money, Colors.green, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StaffSalaryViewScreen()));
                        }),
                        _buildModuleCard(context, 'My Attendance', Icons.calendar_month, Colors.indigo, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceViewScreen()));
                        }),
                        _buildModuleCard(context, 'Apply Leave', Icons.time_to_leave, Colors.purpleAccent, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeaveScreen()));
                        }),
                        _buildModuleCard(context, 'Create Test', Icons.assignment_add, Colors.teal, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTestScreen()));
                        }),
                        _buildModuleCard(context, 'Go Live', Icons.live_tv, Colors.redAccent, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LiveClassSetupScreen()));
                        }),
                        _buildModuleCard(context, 'Complaint Box', Icons.feedback, Colors.indigo, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintBoxScreen()));
                        }),
                        _buildModuleCard(context, 'Exam Results', Icons.leaderboard, Colors.amber, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ResultEntryScreen()));
                        }),
                        _buildModuleCard(context, 'View Syllabus', Icons.library_books, Colors.blueGrey, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SyllabusSelectionScreen()));
                        }),
                      ];

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) => cards[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 32, color: color),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
