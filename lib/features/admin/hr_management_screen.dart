import 'package:flutter/material.dart';
import '../common/widgets/modern_layout.dart';
import '../principal/user_management_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../fees/staff_salary_management_screen.dart';
import '../principal/leave/leave_approval_screen.dart';
import '../data_center/staff_data_screen.dart';

class HRManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'HR Management',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 24),
                _buildSectionTitle('Staff Operations'),
                SizedBox(height: 16),
                _buildModulesGrid(context, constraints),
                SizedBox(height: 32),
                _buildSectionTitle('Staff Directory & Data'),
                SizedBox(height: 16),
                _buildDirectorySection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(Icons.people_alt, color: Colors.white, size: 32),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Human Resources',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your school staff and operations efficiently',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildModulesGrid(BuildContext context, BoxConstraints constraints) {
    int crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildModuleCard(
          context,
          'Mark Attendance',
          Icons.how_to_reg,
          Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarkAttendanceScreen(initialIndex: 1))),
        ),
        _buildModuleCard(
          context,
          'Leave Requests',
          Icons.event_busy,
          Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApprovalScreen())),
        ),
        _buildModuleCard(
          context,
          'Staff Salaries',
          Icons.payments,
          Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffSalaryManagementScreen())),
        ),
        _buildModuleCard(
          context,
          'User Approvals',
          Icons.playlist_add_check,
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen())),
        ),
      ],
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorySection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDirectoryCard(
            context,
            'Teacher Directory',
            'View and manage all faculty members',
            Icons.school,
            Colors.teal,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen())),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildDirectoryCard(
            context,
            'Staff Data',
            'Detailed records of non-teaching staff',
            Icons.assignment_ind,
            Colors.brown,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffDataScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectoryCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
