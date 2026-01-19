
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../attendance/attendance_view_screen.dart';
import '../fees/fee_status_screen.dart';
import '../fees/fee_status_screen.dart';
import '../common/routine_view_screen.dart';
import '../communication/announcement_screen.dart';
import '../results/student_result_screen.dart';
import '../profile/profile_screen.dart';
import '../homework/homework_screen.dart';
import '../../data/services/user_service.dart';
import '../notification/notification_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../common/leave/apply_leave_screen.dart';
import 'test/student_test_list_screen.dart';
import 'classes/student_online_class_list.dart';
import '../common/widgets/notification_badge_wrapper.dart';
import '../common/widgets/dashboard_profile_card.dart';

class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
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
      drawer: _buildDrawer(context, authService),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardProfileCard(),

            SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
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
                   _buildModuleCard(context, 'Write to School', Icons.mail, Colors.indigo, () async {
                      final userService = Provider.of<UserService>(context, listen: false);
                      final email = await userService.getPrincipalEmail();
                      if (email != null) {
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: email,
                          query: 'subject=Query from Student',
                        );
                        if (await canLaunchUrl(emailLaunchUri)) {
                          await launchUrl(emailLaunchUri);
                        } else {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch email app')));
                        }
                      } else {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Principal email not found')));
                      }
                   }),
                   _buildModuleCard(context, 'Online Test', Icons.quiz, Colors.deepOrange, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => StudentTestListScreen()));
                   }),
                   _buildModuleCard(context, 'Apply Leave', Icons.flight_takeoff, Colors.purpleAccent, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeaveScreen()));
                   }),
                   _buildModuleCard(context, 'Online Class', Icons.video_call, Colors.red, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => StudentOnlineClassListScreen()));
                   }),
                   _buildModuleCard(context, 'Exam Results', Icons.emoji_events, Colors.amber, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => StudentResultScreen()));
                   }),
                   _buildModuleCard(context, 'Other Facilities', Icons.more_horiz, Colors.grey, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthService authService) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(authService.userName),
            accountEmail: Text(authService.user?.email ?? "student@school.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text("S", style: TextStyle(fontSize: 24)),
            ),
            decoration: BoxDecoration(color: AppColors.primary),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
           ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => authService.signOut(),
          ),
        ],
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
