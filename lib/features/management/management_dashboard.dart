import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
// Feature screens
import '../communication/announcement_screen.dart';
import '../fees/fee_management_screen.dart';
import '../fees/transaction_history_screen.dart';
import '../principal/user_management_screen.dart';
import '../attendance/mark_attendance_screen.dart'; 
import '../common/routine_view_screen.dart'; 
import '../principal/routine_management_screen.dart';
import '../results/result_entry_screen.dart';
import '../fees/teacher_salary_management_screen.dart';
import '../../data/services/user_service.dart';
import '../common/widgets/notification_badge.dart';
import '../common/widgets/dashboard_profile_card.dart';

class ManagementDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    final userName = user?.displayName ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: Text('Management Dashboard'),
        backgroundColor: Colors.blueGrey, // Distinct color
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardProfileCard(),
            SizedBox(height: 8),
            Text('Super Admin Control Panel', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            
            _buildSectionHeader("Administration"),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Provider.of<UserService>(context, listen: false).getPendingUsers(),
                  builder: (context, snapshot) {
                     final hasPending = snapshot.hasData && snapshot.data!.isNotEmpty;
                     return Stack(
                       fit: StackFit.expand,
                       clipBehavior: Clip.none,
                       children: [
                          _buildModuleCard(context, 'User Management', Icons.people_alt, Colors.indigo, () {
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
                _buildModuleCard(context, 'Announcements', Icons.campaign, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen()));
                }),
              ],
            ),
            SizedBox(height: 24),

            _buildSectionHeader("Finance"),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                 _buildModuleCard(context, 'Student Fees', Icons.attach_money, Colors.green, () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => FeeManagementScreen()));
                 }),
                 _buildModuleCard(context, 'Teacher Salary', Icons.payments, Colors.teal, () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherSalaryManagementScreen()));
                 }),
                 _buildModuleCard(context, 'Transaction History', Icons.receipt_long, Colors.brown, () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryScreen()));
                 }),
              ],
            ),
            SizedBox(height: 24),

            _buildSectionHeader("Academics"),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildModuleCard(context, 'Attendance (All)', Icons.fact_check, Colors.blue, () {
                   // Reusing Teacher's Mark Attendance (allows selecting any class)
                   Navigator.push(context, MaterialPageRoute(builder: (_) => MarkAttendanceScreen()));
                }),
                _buildModuleCard(context, 'Exam Results', Icons.assessment, Colors.purple, () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => ResultEntryScreen()));
                }),
                _buildModuleCard(context, 'Class Routine', Icons.schedule, Colors.deepOrange, () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineManagementScreen()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
              backgroundColor: color.withOpacity(0.1),
              radius: 30,
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
