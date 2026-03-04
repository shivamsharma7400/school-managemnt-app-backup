
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/data/services/auth_service.dart';
import 'package:vps/features/attendance/attendance_view_screen.dart';
import 'package:vps/features/common/complaint_box_screen.dart';
import 'package:vps/features/common/leave/apply_leave_screen.dart';
import 'package:vps/features/fees/staff_salary_view_screen.dart';
import 'package:vps/features/profile/profile_screen.dart';
import 'package:vps/features/common/widgets/notification_badge_wrapper.dart';
import 'package:vps/features/common/widgets/dashboard_profile_card.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff Dashboard"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          NotificationBadgeWrapper(
            child: Icon(Icons.notifications),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DashboardProfileCard(),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 5;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 3;
                  }

                  final cards = [
                    _buildDashboardCard(
                      icon: Icons.calendar_today,
                      title: "My Attendance",
                      color: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceViewScreen()));
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.monetization_on,
                      title: "My Salary",
                      color: Colors.green.shade50,
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => StaffSalaryViewScreen()));
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.feedback,
                      title: "Complaint",
                      color: Colors.orange.shade50,
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintBoxScreen()));
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.time_to_leave,
                      title: "Apply Leave",
                      color: Colors.purple.shade50,
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeaveScreen()));
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.person,
                      title: "My Profile",
                      color: Colors.teal.shade50,
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
                      },
                    ),
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color,
                child: Icon(icon, size: 30, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
