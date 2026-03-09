
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../attendance/attendance_view_screen.dart';
import '../fees/fee_status_screen.dart';
import '../common/routine_view_screen.dart';
import '../communication/announcement_screen.dart';
import '../profile/profile_screen.dart';
import '../homework/homework_screen.dart';
import '../common/leave/apply_leave_screen.dart';
import 'test/student_test_list_screen.dart';
import 'classes/student_online_class_list.dart';
import '../common/widgets/notification_badge_wrapper.dart';
import '../common/widgets/dashboard_profile_card.dart';
import 'student_bus_tracker_screen.dart';
import 'exam_dashboard_screen.dart';


import '../common/complaint_box_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.currentUserData ?? {};
    final feeConfig = userData['feeConfig'] as Map<String, dynamic>? ?? {};
    final hasBusFee = feeConfig['Bus Fee'] != false;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        actions: [
          NotificationBadgeWrapper(
            child: Icon(Icons.notifications),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
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
                  // Responsive column count based on screen width
                  int crossAxisCount = 2; // Mobile (default)
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 5; // Desktop
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 3; // Tablet
                  }

                  final cards = [
                     _buildModuleCard(context, 'Attendance', Icons.calendar_today, Colors.blue, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceViewScreen()));
                     }),
                     _buildModuleCard(context, 'Homework', Icons.book, Colors.orange, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkScreen()));
                     }),
                     _buildModuleCard(context, 'Announcements', Icons.campaign, Colors.red, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen()));
                     }),
                     _buildModuleCard(context, 'Fees', Icons.payment, Colors.green, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FeeStatusScreen()));
                     }),
                     _buildModuleCard(context, 'Routines', Icons.schedule, Colors.pink, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineViewScreen()));
                     }),
                     _buildModuleCard(context, 'Profile', Icons.person, Colors.teal, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
                     }),
                     _buildModuleCard(context, 'Complaint Box', Icons.feedback, Colors.indigo, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintBoxScreen()));
                     }),
                     _buildModuleCard(context, 'Online Test', Icons.quiz, Colors.deepOrange, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => StudentTestListScreen()));
                     }),
                     _buildModuleCard(context, 'Apply Leave', Icons.flight_takeoff, Colors.purpleAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeaveScreen()));
                     }),
                     _buildModuleCard(context, 'E-content', Icons.video_call, Colors.red, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => StudentOnlineClassListScreen()));
                     }),
                     _buildModuleCard(context, 'Exams', Icons.assignment, Colors.deepPurple, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDashboardScreen()));
                     }),
                     if (hasBusFee)
                       _buildModuleCard(context, 'Bus Status', Icons.directions_bus, Colors.orange, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentBusTrackerScreen()));
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

