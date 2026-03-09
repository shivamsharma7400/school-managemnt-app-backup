import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vps/features/driver/start_bus_screen.dart';
import 'driver_attendance_screen.dart';
import '../fees/staff_salary_view_screen.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../common/widgets/notification_badge_wrapper.dart';
import '../communication/announcement_screen.dart';
import '../common/leave/apply_leave_screen.dart';
import '../profile/profile_screen.dart';
import '../common/widgets/dashboard_profile_card.dart';

import '../common/complaint_box_screen.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: Colors.blueAccent,
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
                      title: "Attendance",
                      color: Colors.orange.shade100,
                      iconColor: Colors.orange,
                      onTap: () {
                        Get.to(() => const DriverAttendanceScreen());
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.monetization_on,
                      title: "Salary & Payment",
                      color: Colors.green.shade100,
                      iconColor: Colors.green,
                      onTap: () {
                        Get.to(() => StaffSalaryViewScreen());
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.campaign,
                      title: "Announcement",
                      color: Colors.purple.shade100,
                      iconColor: Colors.purple,
                      onTap: () {
                        Get.to(() => AnnouncementScreen());
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.directions_bus,
                      title: "Start Bus",
                      color: Colors.blue.shade100,
                      iconColor: Colors.blue,
                      onTap: () {
                        Get.to(() => const StartBusScreen());
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.flight_takeoff,
                      title: "Apply Leave",
                      color: Colors.pink.shade100,
                      iconColor: Colors.pink,
                      onTap: () {
                        Get.to(() => ApplyLeaveScreen());
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.person,
                      title: "Profile",
                      color: Colors.teal.shade100,
                      iconColor: Colors.teal,
                      onTap: () {
                        Get.to(() => ProfileScreen());
                      },
                    ),

                    _buildDashboardCard(
                      icon: Icons.feedback,
                      title: "Complaint Box",
                      color: Colors.indigo.shade100,
                      iconColor: Colors.indigo,
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintBoxScreen()));
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
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
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
