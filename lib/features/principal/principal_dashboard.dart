
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../attendance/attendance_view_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../fees/fee_management_screen.dart';
import '../fees/transaction_history_screen.dart';
import '../fees/transaction_history_screen.dart';
import 'principal_assistant_screen.dart';
import 'user_management_screen.dart';
import 'routine_management_screen.dart';
import '../communication/announcement_screen.dart';
import '../results/result_entry_screen.dart';
import '../../data/services/auth_service.dart';
import 'widgets/promotion_alert_card.dart';
import '../fees/teacher_salary_management_screen.dart';
import 'student_queries_screen.dart';
import 'school_info_screen.dart';
import '../../data/services/user_service.dart';
import '../common/widgets/notification_badge.dart';
import 'leave/leave_approval_screen.dart';
import '../common/widgets/notification_badge_wrapper.dart';
import '../common/widgets/dashboard_profile_card.dart';


import '../results/principal_result_view_screen.dart';

class PrincipalDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Principal Dashboard'),
         actions: [
          NotificationBadgeWrapper(child: Icon(Icons.notifications)),
          IconButton(icon: Icon(Icons.logout), onPressed: () => authService.signOut()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             DashboardProfileCard(),
            SizedBox(height: 16),
            // Ask AI Card (Full Width)
            Card(
              color: Colors.indigo,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrincipalAssistantScreen())),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                       Container(
                         padding: EdgeInsets.all(12),
                         decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                         child: Icon(Icons.auto_awesome, color: Colors.indigo, size: 28),
                       ),
                       SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Ask AI about School Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                             SizedBox(height: 4),
                             Text('Admission, Finance, Planning & more', style: TextStyle(color: Colors.white70)),
                           ],
                         ),
                       ),
                       Icon(Icons.arrow_forward_ios, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            PromotionAlertCard(),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [

                 _buildModuleCard(context, 'Attendance (All)', Icons.fact_check, Colors.indigoAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MarkAttendanceScreen())); // Reuse generic screen
                 }),
                 _buildModuleCard(context, 'Fee Mgmt', Icons.attach_money, Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FeeManagementScreen()));
                 }),
                 _buildModuleCard(context, 'Transactions', Icons.receipt_long, Colors.brown, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryScreen()));
                 }),
                 // User Mgmt Card with Badge
                 StreamBuilder<List<Map<String, dynamic>>>(
                   stream: Provider.of<UserService>(context, listen: false).getPendingUsers(),
                   builder: (context, snapshot) {
                     final hasPending = snapshot.hasData && snapshot.data!.isNotEmpty;
                     return Stack(
                       fit: StackFit.expand,
                       clipBehavior: Clip.none,
                       children: [
                         _buildModuleCard(context, 'User Mgmt', Icons.people, Colors.orange, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen()));
                         }),
                         if (hasPending)
                           Positioned(
                             top: 8,
                             right: 8,
                             child: GlowingBadge(),
                           ),
                       ],
                     );
                   },
                 ),
                 _buildModuleCard(context, 'Routine Mgmt', Icons.dashboard_customize, Colors.teal, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineManagementScreen()));
                 }),
                 _buildModuleCard(context, 'Announcements', Icons.campaign, Colors.red, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen()));
                 }),
                 _buildModuleCard(context, 'Leave Requests', Icons.approval, Colors.pink, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApprovalScreen()));
                 }),
                 _buildModuleCard(context, 'Teacher Fees', Icons.monetization_on_outlined, Colors.indigo, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherSalaryManagementScreen()));
                 }),
                 _buildModuleCard(context, 'Student Queries', Icons.question_answer, Colors.teal, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQueriesScreen()));
                 }),
                 _buildModuleCard(context, 'Train AI (School Info)', Icons.psychology, Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SchoolInfoScreen()));
                 }),
                 _buildModuleCard(context, 'Exam Results', Icons.emoji_events, Colors.amber, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PrincipalResultViewScreen()));
                 }),
              ],
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
