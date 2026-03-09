import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/features/attendance/mark_attendance_screen.dart';

import 'package:vps/features/homework/create_assignment_screen.dart';
import 'package:vps/features/teacher/student_search_screen.dart';
import 'package:vps/data/services/auth_service.dart';
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
  const TeacherDashboard({super.key});

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
                      final userData = authService.currentUserData;
                      final permissions = userData?['permissions'] as Map<String, dynamic>? ?? {};

                      bool hasPerm(String key) => permissions[key] ?? true;

                      final assignedClass = classes.firstWhere(
                        (c) => c.teacherId == authService.user?.uid,
                        orElse: () => ClassModel(id: '', name: 'None', teacherId: ''),
                      );

                      final cards = [
                        if (assignedClass.id.isNotEmpty && hasPerm('class_details'))
                          _buildModuleCard(context, 'Class Details', Icons.groups, Colors.indigo, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ClassStudentsScreen(assignedClass: assignedClass)));
                          }),
                        if (hasPerm('attendance'))
                          _buildModuleCard(context, 'Attendance', Icons.fact_check, Colors.blue, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MarkAttendanceScreen()));
                          }),
                        if (hasPerm('homework'))
                          _buildModuleCard(context, 'Homework', Icons.assignment, Colors.orange, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentScreen()));
                          }),
                        if (hasPerm('announcements'))
                          _buildModuleCard(context, 'Announcements', Icons.campaign, Colors.red, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen()));
                          }),
                        if (hasPerm('contact_parents'))
                          _buildModuleCard(context, 'Contact Parents', Icons.contact_phone, Colors.purple, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => StudentSearchScreen()));
                          }),
                        if (hasPerm('salary_payment'))
                          _buildModuleCard(context, 'Salary/Payment', Icons.attach_money, Colors.green, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => StaffSalaryViewScreen()));
                          }),
                        if (hasPerm('my_attendance'))
                          _buildModuleCard(context, 'My Attendance', Icons.calendar_month, Colors.indigo, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceViewScreen()));
                          }),
                        if (hasPerm('apply_leave'))
                          _buildModuleCard(context, 'Apply Leave', Icons.time_to_leave, Colors.purpleAccent, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeaveScreen()));
                          }),
                        if (hasPerm('create_test'))
                          _buildModuleCard(context, 'Create Test', Icons.assignment_add, Colors.teal, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTestScreen()));
                          }),
                        if (hasPerm('go_live'))
                          _buildModuleCard(context, 'Go Live', Icons.live_tv, Colors.redAccent, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LiveClassSetupScreen()));
                          }),
                        if (hasPerm('complaint_box'))
                          _buildModuleCard(context, 'Complaint Box', Icons.feedback, Colors.indigo, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintBoxScreen()));
                          }),
                        if (hasPerm('exam_results'))
                          _buildModuleCard(context, 'Exam Results', Icons.leaderboard, Colors.amber, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ResultEntryScreen()));
                          }),
                        if (hasPerm('view_syllabus'))
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
