import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veena_public_school/features/driver/start_bus_screen.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              icon: Icons.calendar_today,
              title: "Attendance",
              color: Colors.orange.shade100,
              iconColor: Colors.orange,
              onTap: () {
                // TODO: Navigate to Attendance
              },
            ),
            _buildDashboardCard(
              icon: Icons.monetization_on,
              title: "Salary & Payment",
              color: Colors.green.shade100,
              iconColor: Colors.green,
              onTap: () {
                // TODO: Navigate to Salary
              },
            ),
            _buildDashboardCard(
              icon: Icons.campaign,
              title: "Announcement",
              color: Colors.purple.shade100,
              iconColor: Colors.purple,
              onTap: () {
                // TODO: Navigate to Announcement
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
    );
  }
}
