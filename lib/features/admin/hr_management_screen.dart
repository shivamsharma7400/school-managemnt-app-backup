import 'package:flutter/material.dart';
import '../common/widgets/modern_layout.dart';
import '../principal/user_management_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../fees/staff_salary_management_screen.dart';
import '../principal/leave/leave_approval_screen.dart';
import 'package:provider/provider.dart';
import '../../data/services/user_service.dart';

class HRManagementScreen extends StatelessWidget {
  const HRManagementScreen({super.key});

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
                _buildSectionTitle('Staff Permissions Management'),
                SizedBox(height: 16),
                _buildPermissionTable(context),
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

  Widget _buildPermissionTable(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final permissions = [
      {'key': 'user_approval', 'label': 'User Approval'},
      {'key': 'exam_setup', 'label': 'Exam Setup'},
      {'key': 'ai_training', 'label': 'AI Training'},
      {'key': 'ai_reports', 'label': 'AI Reports'},
      {'key': 'student_fee', 'label': 'Student Fee'},
      {'key': 'staff_salary', 'label': 'Staff Salary'},
      {'key': 'data_center', 'label': 'Data Center'},
      {'key': 'syllabus', 'label': 'Syllabus'},
      {'key': 'complaint_box', 'label': 'Complaint Box'},
      {'key': 'leave_request', 'label': 'Leave Request Accept'},
      {'key': 'attendance', 'label': 'Attendance'},
    ];

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No management/staff users found'));
        }

        final managementUsers = snapshot.data!.where((u) {
          final role = u['role']?.toString().toLowerCase();
          return role != 'student' && 
                 role != 'teacher' && 
                 role != 'pending' && 
                 role != 'passed_out' &&
                 role != 'principal' &&
                 role != 'admin';
        }).toList();

        if (managementUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text('No management/staff users found', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 20,
              headingRowHeight: 56,
              dataRowHeight: 60,
              headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
              showCheckboxColumn: false,
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text('NAME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.indigo.shade900, letterSpacing: 0.5)),
                  ),
                ),
                ...permissions.map((p) => DataColumn(
                      label: Text(
                        p['label']!.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.indigo.shade900, letterSpacing: 0.5),
                      ),
                    )),
              ],
              rows: managementUsers.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                final userPermissions = user['permissions'] as Map<String, dynamic>? ?? {};
                final isEven = index % 2 == 0;
                
                return DataRow(
                  color: WidgetStateProperty.all(isEven ? Colors.white : Colors.grey.shade50),
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          user['name'] ?? 'Unknown',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    ...permissions.map((p) => DataCell(
                          Center(
                            child: Transform.scale(
                              scale: 0.9,
                              child: Checkbox(
                                value: userPermissions[p['key']] == true,
                                activeColor: Colors.indigo.shade600,
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  userService.updateUserPermission(user['id'], p['key']!, val ?? false);
                                },
                              ),
                            ),
                          ),
                        )),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
