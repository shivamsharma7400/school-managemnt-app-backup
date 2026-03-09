import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/user_service.dart';
import '../common/widgets/modern_layout.dart';
import '../common/widgets/dashboard_widgets.dart';
import '../principal/principal_assistant_screen.dart';
import '../principal/user_management_screen.dart';
import '../communication/announcement_screen.dart';
import '../principal/leave/leave_approval_screen.dart';
import '../fees/fee_management_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../principal/routine_management_screen.dart';
import '../results/principal_result_view_screen.dart';
import '../../data/services/announcement_service.dart';
import '../../data/models/announcement_model.dart';
import '../../data/services/complaint_service.dart';
import '../../data/services/leave_service.dart';
import '../principal/principal_complaint_screen.dart';
import '../principal/strategic_planning_screen.dart';
import '../../data/services/strategic_planning_service.dart';
import '../../data/models/strategic_task.dart';
import 'package:intl/intl.dart';
import 'hr_management_screen.dart';
import 'package:rxdart/rxdart.dart';
import '../principal/exam_setup_screen.dart';

class DashboardData {
  final int pendingUsers;
  final int pendingLeaves;
  final int pendingComplaints;
  final List<StrategicTask> todaysTasks;

  DashboardData(this.pendingUsers, this.pendingLeaves, this.pendingComplaints, this.todaysTasks);
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'Admin Dashboard',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricsGrid(context, constraints),
                SizedBox(height: 24),
                if (isMobile) ...[
                   _buildMainActions(context, constraints),
                   SizedBox(height: 24),
                   _buildRecentActivity(context),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMainActions(context, constraints)),
                      SizedBox(width: 24),
                      Expanded(child: _buildRecentActivity(context)),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, BoxConstraints constraints) {
    int crossAxisCount = 4;
    double childAspectRatio = 1.5;

    if (constraints.maxWidth < 600) {
      crossAxisCount = 1;
      childAspectRatio = 2.2;
    } else if (constraints.maxWidth < 1100) {
      crossAxisCount = 3;
      childAspectRatio = 1.4;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        AttendancePieChartCard(),
        FeeCollectionMetricCard(),
        BusStatusMapCard(),
        PendingApprovalsMetricCard(),
      ],
    );
  }

  Widget _buildMainActions(BuildContext context, BoxConstraints constraints) {
    int moduleCrossAxisCount = 3;
    if (constraints.maxWidth < 600) {
      moduleCrossAxisCount = 2;
    }

    final userService = Provider.of<UserService>(context);
    final leaveService = Provider.of<LeaveService>(context);
    final complaintService = Provider.of<ComplaintService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Required',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        
        StreamBuilder<DashboardData>(
          stream: Rx.combineLatest4(
            userService.getPendingUsersStream(), 
            leaveService.getPendingLeaves().map((list) => list.length),
            complaintService.getPendingComplaintsCount(),
            Provider.of<StrategicPlanningService>(context, listen: false).getActiveTasks(),
            (a, b, c, d) {
              final tasks = d;
              final today = DateTime.now();
              final todaysTasks = tasks.where((t) {
                return t.date.year == today.year && 
                       t.date.month == today.month && 
                       t.date.day == today.day;
              }).toList();
              return DashboardData(a, b, c, todaysTasks);
            },
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data;
            final pendingUsers = data?.pendingUsers ?? 0;
            final pendingLeaves = data?.pendingLeaves ?? 0;
            final pendingComplaints = data?.pendingComplaints ?? 0;
            final todaysTasks = data?.todaysTasks ?? [];

            if (pendingUsers == 0 && pendingLeaves == 0 && pendingComplaints == 0 && todaysTasks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green),
                    SizedBox(height: 12),
                    Text(
                      'Everything is clear',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      'No pending actions required',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                if (todaysTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ActionCard(
                      title: 'Scheduled Work',
                      description: '${todaysTasks.length} tasks scheduled for today',
                      badgeText: 'Priority',
                      badgeColor: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StrategicPlanningScreen())),
                    ),
                  ),
                if (pendingUsers > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ActionCard(
                      title: 'User Management',
                      description: '$pendingUsers pending registration approvals',
                      badgeText: 'Pending',
                      badgeColor: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen())),
                    ),
                  ),
                if (pendingLeaves > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ActionCard(
                      title: 'Leave Requests',
                      description: '$pendingLeaves leave requests require moderation',
                      badgeText: 'Urgent',
                      badgeColor: Colors.red,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApprovalScreen())),
                    ),
                  ),
                 if (pendingComplaints > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ActionCard(
                      title: 'Complaint Box',
                      description: '$pendingComplaints new complaints received',
                      badgeText: 'Review',
                      badgeColor: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrincipalComplaintListScreen())),
                    ),
                  ), 
              ],
            );
          },
        ),
        SizedBox(height: 24),
        Text(
          'Quick Modules',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: moduleCrossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildModuleItem(context, 'Attendance', Icons.fact_check, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarkAttendanceScreen()))),
            _buildModuleItem(context, 'Fee Mgmt', Icons.attach_money, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeeManagementScreen()))),
            _buildModuleItem(context, 'AI Reports', Icons.auto_awesome, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrincipalAssistantScreen()))),
            _buildModuleItem(context, 'Exams', Icons.assignment, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrincipalResultViewScreen()))),
            _buildModuleItem(context, 'Exam Setup', Icons.settings_applications, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamSetupScreen()))),
            _buildModuleItem(context, 'Routine', Icons.schedule, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineManagementScreen()))),
            _buildModuleItem(context, 'Announcements', Icons.campaign, Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen()))),
            _buildModuleItem(context, 'Complaint Box', Icons.inbox, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrincipalComplaintListScreen()))),
            _buildModuleItem(context, 'HR Mgmt', Icons.people_alt, Colors.deepPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HRManagementScreen()))),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final announcementService = Provider.of<AnnouncementService>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Announcements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Announcement>>(
              stream: announcementService.getAnnouncements('principal'), // Admin sees same as principal for now
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(fontSize: 12, color: Colors.red)));
                }

                final announcements = snapshot.data?.take(3).toList() ?? [];

                if (announcements.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No announcements yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  );
                }

                return Column(
                  children: announcements.map((item) {
                    return AnnouncementCard(
                      title: item.title,
                      date: DateFormat('MMM d, y').format(item.date),
                      type: item.type,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen())),
                child: const Text('Send new announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
