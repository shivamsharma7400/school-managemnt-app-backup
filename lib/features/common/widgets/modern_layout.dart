import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vps/core/constants/app_constants.dart';
import 'package:vps/data/services/auth_service.dart';
import 'package:vps/data/services/school_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Feature screens for navigation
import 'package:vps/features/attendance/mark_attendance_screen.dart';
import 'package:vps/features/principal/routine_management_screen.dart';

import 'package:vps/features/fees/fee_management_screen.dart';
import 'package:vps/features/fees/staff_salary_management_screen.dart';
import 'package:vps/features/fees/transaction_history_screen.dart';
import 'package:vps/features/principal/user_management_screen.dart';
import 'package:vps/features/communication/announcement_screen.dart';
import 'package:vps/features/transport/bus_management_screen.dart';
import 'package:vps/features/data_center/student_data_screen.dart';
import 'package:vps/features/data_center/teacher_data_screen.dart';
import 'package:vps/features/data_center/staff_data_screen.dart';
import 'package:vps/features/principal/leave/leave_approval_screen.dart';
import 'package:vps/features/principal/student_queries_screen.dart';
import 'package:vps/features/principal/principal_assistant_screen.dart';
import 'package:vps/features/principal/school_info_screen.dart';
import 'package:vps/features/data_center/school_data_analysis_screen.dart';
import 'package:vps/features/principal/exam_setup_screen.dart';
import 'package:vps/features/academics/syllabus_report_screen.dart';
import 'package:vps/features/principal/strategic_planning_screen.dart';
import 'package:vps/features/data_center/data_export_screen.dart';
import 'package:vps/features/principal/principal_complaint_screen.dart';
import 'package:vps/features/profile/profile_screen.dart';



class ModernLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool showSidebar;

  const ModernLayout({
    Key? key,
    required this.child,
    this.title = 'Dashboard',
    this.actions,
    this.showSidebar = true,
  }) : super(key: key);

  @override
  _ModernLayoutState createState() => _ModernLayoutState();
}

class _ModernLayoutState extends State<ModernLayout> {
  @override
  void initState() {
    super.initState();
    // Force Landscape for Principal/Management
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset to any orientation on dispose
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          drawer: isMobile && widget.showSidebar 
              ? Drawer(
                  child: _buildSidebar(context),
                  width: 260,
                  backgroundColor: AppColors.sidebarBackground,
                ) 
              : null,
          body: Row(
            children: [
              if (!isMobile && widget.showSidebar) _buildSidebar(context),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, isMobile),
                    Expanded(
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final config = Provider.of<SchoolConfigService>(context);
    
    return Container(
      width: 260,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: InkWell(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Row(
                children: [
                   if (config.schoolLogoUrl.isNotEmpty) 
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.transparent,
                        backgroundImage: NetworkImage(config.schoolLogoUrl),
                      )
                   else
                      Icon(Icons.school, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      config.schoolName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard, 
                  title: 'Dashboard', 
                  isActive: true, 
                  onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                
                _SidebarCategory(
                  icon: Icons.school,
                  title: 'Academic',
                  items: [
                    _SidebarSubItem(title: 'Attendance', onTap: () => _navigateTo(context, MarkAttendanceScreen())),
                    _SidebarSubItem(title: 'Routines', onTap: () => _navigateTo(context, RoutineManagementScreen())),

                    _SidebarSubItem(title: 'Exam Setup', onTap: () => _navigateTo(context, ExamSetupScreen())),
                    _SidebarSubItem(title: 'Syllabus Report', onTap: () => _navigateTo(context, SyllabusReportScreen())),
                    if (authService.role == 'principal' || authService.role == 'admin') ...[
                      _SidebarSubItem(title: 'Complaint Box', onTap: () => _navigateTo(context, PrincipalComplaintListScreen())),
                      _SidebarSubItem(title: 'Leave Requests', onTap: () => _navigateTo(context, LeaveApprovalScreen())),
                    ],
                  ],
                ),

                if (authService.role == 'principal' || authService.role == 'admin')
                  _SidebarCategory(
                    icon: Icons.auto_awesome,
                    title: 'Gen AI',
                    items: [
                      _SidebarSubItem(title: 'AI Reports', onTap: () => _navigateTo(context, PrincipalAssistantScreen())),
                      _SidebarSubItem(title: 'AI Training', onTap: () => _navigateTo(context, SchoolInfoScreen())),
                      _SidebarSubItem(title: 'Student Queries', onTap: () => _navigateTo(context, StudentQueriesScreen())),
                    ],
                  ),

                _SidebarCategory(
                  icon: Icons.account_balance_wallet,
                  title: 'Finance',
                  items: [
                    _SidebarSubItem(title: 'Student Fee', onTap: () => _navigateTo(context, FeeManagementScreen())),
                    _SidebarSubItem(title: 'Staff Salary', onTap: () => _navigateTo(context, StaffSalaryManagementScreen())),
                    _SidebarSubItem(title: 'Transactions', onTap: () => _navigateTo(context, TransactionHistoryScreen())),
                  ],
                ),

                _SidebarCategory(
                  icon: Icons.admin_panel_settings,
                  title: 'Administration',
                  items: [
                    _SidebarSubItem(title: 'User Management', onTap: () => _navigateTo(context, UserManagementScreen())),
                    _SidebarSubItem(title: 'Announcement', onTap: () => _navigateTo(context, AnnouncementScreen())),
                    _SidebarSubItem(title: 'Bus Management', onTap: () => _navigateTo(context, BusManagementScreen())),
                    
                    _SidebarSubItem(title: 'Strategic Planning', onTap: () => _navigateTo(context, StrategicPlanningScreen())),
                  ],
                ),

                _SidebarCategory(
                  icon: Icons.analytics,
                  title: 'Data Center',
                  items: [
                    _SidebarSubItem(title: 'Student Data', onTap: () => _navigateTo(context, StudentDataScreen())),
                    _SidebarSubItem(title: 'Teachers Data', onTap: () => _navigateTo(context, TeacherDataScreen())),
                    _SidebarSubItem(title: 'Staff Data', onTap: () => _navigateTo(context, StaffDataScreen())),
                    _SidebarSubItem(title: 'School Analysis', onTap: () => _navigateTo(context, SchoolDataAnalysisScreen())),
                    _SidebarSubItem(title: 'Data Export', onTap: () => _navigateTo(context, const DataExportScreen())),
                  ],
                ),

                _SidebarItem(icon: Icons.settings, title: 'Settings', onTap: () => _navigateTo(context, ProfileScreen())),
                _SidebarItem(
                  icon: Icons.logout, 
                  title: 'Logout', 
                  onTap: () {
                    authService.signOut();
                  }
                ),
              ],
            ),
          ),
          _buildQuickActions(),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              const url = 'https://google.com'; // Placeholder link
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.sidebarBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Guide'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          
          Text(
            widget.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          if (!isMobile) ...[
            _HeaderIcon(icon: Icons.search),
            _HeaderIcon(icon: Icons.notifications_none),
            _HeaderIcon(icon: Icons.person_outline),
            SizedBox(width: 8),
          ],
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.modernPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(isMobile ? 'Exams' : 'Scheduled Exams', style: TextStyle(color: Colors.white, fontSize: 12)),
                SizedBox(width: 8),
                Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarCategory extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Widget> items;

  const _SidebarCategory({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  State<_SidebarCategory> createState() => _SidebarCategoryState();
}

class _SidebarCategoryState extends State<_SidebarCategory> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: widget.icon,
          title: widget.title,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          trailing: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.white70,
            size: 18,
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              children: widget.items,
            ),
          ),
      ],
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SidebarSubItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.white60, fontSize: 13),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.sidebarItemActive : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Icon(icon, color: Colors.grey.shade600, size: 24),
    );
  }
}
