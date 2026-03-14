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
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.indigo.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Teacher Permissions'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Management group Permission'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Staff permission'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 500, // Fixed height for the table area
            child: TabBarView(
              children: [
                _PermissionTable(roleFilter: const ['teacher']),
                _PermissionTable(roleFilter: const ['management']),
                _PermissionTable(roleFilter: const ['staff', 'driver']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTable extends StatelessWidget {
  final List<String> roleFilter;

  const _PermissionTable({required this.roleFilter});

  List<Map<String, dynamic>> _getPermissionsForRole(String role) {
    if (role == 'teacher') {
      return [
        {'key': 'class_details', 'label': 'Class Details', 'icon': Icons.class_outlined},
        {'key': 'attendance', 'label': 'Attendance', 'icon': Icons.how_to_reg},
        {'key': 'homework', 'label': 'Homework', 'icon': Icons.menu_book},
        {'key': 'announcements', 'label': 'Announcements', 'icon': Icons.campaign},
        {'key': 'contact_parents', 'label': 'Contact Parents', 'icon': Icons.contact_phone},
        {'key': 'salary_payment', 'label': 'Salary/Payment', 'icon': Icons.payments},
        {'key': 'my_attendance', 'label': 'My Attendance', 'icon': Icons.event_available},
        {'key': 'apply_leave', 'label': 'Apply Leave', 'icon': Icons.time_to_leave},
        {'key': 'create_test', 'label': 'Create Test', 'icon': Icons.quiz},
        {'key': 'go_live', 'label': 'Go Live', 'icon': Icons.live_tv},
        {'key': 'complaint_box', 'label': 'Complaint Box', 'icon': Icons.report_problem},
        {'key': 'exam_results', 'label': 'Exam Results', 'icon': Icons.grade},
        {'key': 'view_syllabus', 'label': 'View Syllabus', 'icon': Icons.import_contacts},
      ];
    } else {
      // Management and Staff roles
      return [
        {'key': 'attendance', 'label': 'Attendance', 'icon': Icons.how_to_reg},
        {'key': 'fee_mgmt', 'label': 'Fee Mgmt', 'icon': Icons.account_balance_wallet},
        {'key': 'exams', 'label': 'Exams', 'icon': Icons.assignment},
        {'key': 'exam_setup', 'label': 'Exam Setup', 'icon': Icons.settings_suggest},
        {'key': 'routine', 'label': 'Routine', 'icon': Icons.schedule},
        {'key': 'announcements', 'label': 'Announcements', 'icon': Icons.campaign},
        {'key': 'complaint_box', 'label': 'Complaint Box', 'icon': Icons.report_problem},
        {'key': 'user_management', 'label': 'User Mgmt', 'icon': Icons.people_outline},
        {'key': 'leave_requests', 'label': 'Leave Requests', 'icon': Icons.event_busy},
        {'key': 'scheduled_work', 'label': 'Scheduled Work', 'icon': Icons.work_history},
        {'key': 'data_center', 'label': 'Data Center', 'icon': Icons.storage},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final String primaryRole = roleFilter.first;
    final permissions = _getPermissionsForRole(primaryRole);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final filteredUsers = snapshot.data?.where((u) {
          final role = u['role']?.toString().toLowerCase() ?? '';
          return roleFilter.contains(role);
        }).toList() ?? [];

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('No users found for this category', style: TextStyle(color: Colors.grey)),
              ],
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
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical, // Allow vertical scrolling within the table if needed
              child: DataTable(
                columnSpacing: 32,
                horizontalMargin: 20,
                headingRowHeight: 56,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50.withOpacity(0.5)),
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: 150,
                      child: Text('NAME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.indigo.shade900, letterSpacing: 0.5)),
                    ),
                  ),
                  ...permissions.map((p) => DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(p['icon'] as IconData, size: 14, color: Colors.indigo.shade700),
                            const SizedBox(width: 8),
                            Text(
                              p['label']!.toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.indigo.shade900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      )),
                ],
                rows: filteredUsers.asMap().entries.map((entry) {
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo.shade900.withOpacity(0.8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ...permissions.map((p) => DataCell(
                            Center(
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: userPermissions[p['key']] ?? true,
                                  activeColor: Colors.indigo.shade600,
                                  onChanged: (val) {
                                    userService.updateUserPermission(user['id'] ?? user['uid'], p['key']!, val);
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
          ),
        );
      },
    );
  }
}
