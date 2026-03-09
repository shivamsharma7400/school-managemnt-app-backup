import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vps/core/constants/app_constants.dart';
import 'package:vps/data/services/auth_service.dart';
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
import 'package:vps/features/fees/budget_calculation_screen.dart';
import 'package:vps/features/principal/principal_complaint_screen.dart';
import 'package:vps/features/profile/profile_screen.dart';
import 'package:vps/features/admin/hr_management_screen.dart';



class ModernLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool showSidebar;

  const ModernLayout({
    super.key,
    required this.child,
    this.title = 'Dashboard',
    this.actions,
    this.showSidebar = true,
  });

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
                  width: 260,
                  backgroundColor: AppColors.sidebarBackground,
                  child: _buildSidebar(context),
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
                   CircleAvatar(
                     radius: 16,
                     backgroundColor: Colors.transparent,
                     backgroundImage: AssetImage('assets/logos/logo.png'),
                   ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.appName,
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
                    _SidebarSubItem(title: 'Attendance', icon: Icons.how_to_reg, onTap: () => _navigateTo(context, MarkAttendanceScreen())),
                    _SidebarSubItem(title: 'Routines', icon: Icons.schedule, onTap: () => _navigateTo(context, RoutineManagementScreen())),

                    _SidebarSubItem(title: 'Exam Setup', icon: Icons.settings_suggest, onTap: () => _navigateTo(context, ExamSetupScreen())),
                    _SidebarSubItem(title: 'Syllabus Report', icon: Icons.assignment, onTap: () => _navigateTo(context, SyllabusReportScreen())),
                    if (authService.role == 'principal' || authService.role == 'admin') ...[
                      _SidebarSubItem(title: 'Complaint Box', icon: Icons.report_problem, onTap: () => _navigateTo(context, PrincipalComplaintListScreen())),
                      _SidebarSubItem(title: 'Leave Requests', icon: Icons.event_busy, onTap: () => _navigateTo(context, LeaveApprovalScreen())),
                    ],
                  ],
                ),

                if (authService.role == 'principal' || authService.role == 'admin')
                  _SidebarCategory(
                    icon: Icons.auto_awesome,
                    title: 'Gen AI',
                    items: [
                      _SidebarSubItem(title: 'AI Reports', icon: Icons.auto_graph, onTap: () => _navigateTo(context, PrincipalAssistantScreen())),
                      _SidebarSubItem(title: 'AI Training', icon: Icons.model_training, onTap: () => _navigateTo(context, SchoolInfoScreen())),
                      _SidebarSubItem(title: 'Student Queries', icon: Icons.question_answer, onTap: () => _navigateTo(context, StudentQueriesScreen())),
                    ],
                  ),

                _SidebarCategory(
                  icon: Icons.account_balance_wallet,
                  title: 'Finance',
                  items: [
                    _SidebarSubItem(title: 'Student Fee', icon: Icons.payments, onTap: () => _navigateTo(context, FeeManagementScreen())),
                    _SidebarSubItem(title: 'Staff Salary', icon: Icons.account_balance, onTap: () => _navigateTo(context, StaffSalaryManagementScreen())),
                    _SidebarSubItem(title: 'Transactions', icon: Icons.history, onTap: () => _navigateTo(context, TransactionHistoryScreen())),
                    _SidebarSubItem(title: 'School Budget', icon: Icons.pie_chart, onTap: () => _navigateTo(context, BudgetCalculationScreen())),
                  ],
                ),

                _SidebarCategory(
                  icon: Icons.admin_panel_settings,
                  title: 'Administration',
                  items: [
                    _SidebarSubItem(title: 'User Management', icon: Icons.people, onTap: () => _navigateTo(context, UserManagementScreen())),
                    _SidebarSubItem(title: 'HR Management', icon: Icons.assignment_ind, onTap: () => _navigateTo(context, HRManagementScreen())),
                    _SidebarSubItem(title: 'Announcement', icon: Icons.campaign, onTap: () => _navigateTo(context, AnnouncementScreen())),
                    _SidebarSubItem(title: 'Bus Management', icon: Icons.directions_bus, onTap: () => _navigateTo(context, BusManagementScreen())),
                    
                    _SidebarSubItem(title: 'Strategic Planning', icon: Icons.insights, onTap: () => _navigateTo(context, StrategicPlanningScreen())),
                  ],
                ),

                _SidebarCategory(
                  icon: Icons.analytics,
                  title: 'Data Center',
                  items: [
                    _SidebarSubItem(title: 'Student Data', icon: Icons.person, onTap: () => _navigateTo(context, StudentDataScreen())),
                    _SidebarSubItem(title: 'Teachers Data', icon: Icons.person_search, onTap: () => _navigateTo(context, TeacherDataScreen())),
                    _SidebarSubItem(title: 'Staff Data', icon: Icons.badge, onTap: () => _navigateTo(context, StaffDataScreen())),
                    _SidebarSubItem(title: 'School Analysis', icon: Icons.analytics, onTap: () => _navigateTo(context, SchoolDataAnalysisScreen())),
                    _SidebarSubItem(title: 'Data Export', icon: Icons.file_download, onTap: () => _navigateTo(context, const DataExportScreen())),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final authService = Provider.of<AuthService>(context);
    
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
            _HeaderIcon(
              icon: Icons.search, 
              onTap: () => showSearch(
                context: context, 
                delegate: _MenuSearchDelegate(context: context, authRole: authService.role ?? ''),
              ),
            ),
            _buildProfileIcon(context, authService),
            SizedBox(width: 16),
          ],
          InkWell(
            onTap: () => _navigateTo(context, ExamSetupScreen()),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.modernPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.modernPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Icon(Icons.event_available, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(isMobile ? 'Exams' : 'Scheduled Exams', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context, AuthService authService) {
    final photoUrl = authService.currentUserData?['photoUrl'];
    
    return GestureDetector(
      onTap: () => _navigateTo(context, ProfileScreen()),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.dashboardBackground,
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Icon(Icons.person, color: AppColors.modernPrimary, size: 20)
              : null,
        ),
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
  final IconData? icon;

  const _SidebarSubItem({
    required this.title,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: Colors.white60, size: 20) : null,
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
  final VoidCallback? onTap;
  const _HeaderIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: IconButton(
        icon: Icon(icon, color: Colors.grey.shade600, size: 24),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
        splashRadius: 20,
      ),
    );
  }
}

class _MenuSearchDelegate extends SearchDelegate {
  final BuildContext context;
  final String authRole;

  _MenuSearchDelegate({required this.context, required this.authRole});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey.shade600),
        titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
      ),
    );
  }

  List<Map<String, dynamic>> _getSearchItems() {
    final List<Map<String, dynamic>> items = [
      {'title': 'Dashboard', 'screen': null, 'icon': Icons.dashboard},
      {'title': 'Attendance', 'screen': MarkAttendanceScreen(), 'icon': Icons.calendar_today},
      {'title': 'Routines', 'screen': RoutineManagementScreen(), 'icon': Icons.schedule},
      {'title': 'Exam Setup', 'screen': ExamSetupScreen(), 'icon': Icons.edit_note},
      {'title': 'Syllabus Report', 'screen': SyllabusReportScreen(), 'icon': Icons.assignment},
      {'title': 'Student Fee', 'screen': FeeManagementScreen(), 'icon': Icons.payments},
      {'title': 'Staff Salary', 'screen': StaffSalaryManagementScreen(), 'icon': Icons.money},
      {'title': 'School Budget', 'screen': BudgetCalculationScreen(), 'icon': Icons.account_balance},
      {'title': 'Transactions', 'screen': TransactionHistoryScreen(), 'icon': Icons.history},
      {'title': 'User Management', 'screen': UserManagementScreen(), 'icon': Icons.people},
      {'title': 'HR Management', 'screen': HRManagementScreen(), 'icon': Icons.assignment_ind},
      {'title': 'Announcement', 'screen': AnnouncementScreen(), 'icon': Icons.campaign},
      {'title': 'Bus Management', 'screen': BusManagementScreen(), 'icon': Icons.directions_bus},
      {'title': 'Strategic Planning', 'screen': StrategicPlanningScreen(), 'icon': Icons.insights},
      {'title': 'Student Data', 'screen': StudentDataScreen(), 'icon': Icons.person},
      {'title': 'Teachers Data', 'screen': TeacherDataScreen(), 'icon': Icons.person_search},
      {'title': 'Staff Data', 'screen': StaffDataScreen(), 'icon': Icons.badge},
      {'title': 'School Analysis', 'screen': SchoolDataAnalysisScreen(), 'icon': Icons.analytics},
      {'title': 'Data Export', 'screen': DataExportScreen(), 'icon': Icons.file_download},
      {'title': 'Settings', 'screen': ProfileScreen(), 'icon': Icons.settings},
    ];

    if (authRole == 'principal' || authRole == 'admin') {
      items.addAll([
        {'title': 'Complaint Box', 'screen': PrincipalComplaintListScreen(), 'icon': Icons.feedback},
        {'title': 'Leave Requests', 'screen': LeaveApprovalScreen(), 'icon': Icons.event_busy},
        {'title': 'AI Reports', 'screen': PrincipalAssistantScreen(), 'icon': Icons.auto_awesome},
        {'title': 'AI Training', 'screen': SchoolInfoScreen(), 'icon': Icons.model_training},
        {'title': 'Student Queries', 'screen': StudentQueriesScreen(), 'icon': Icons.question_answer},
      ]);
    }

    return items;
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: Colors.grey.shade400),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final allItems = _getSearchItems();
    final results = allItems.where((item) => item['title'].toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade200),
            ),
            SizedBox(height: 24),
            Text(
              'No results found for "$query"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Try adjusting your search to find what you need',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: results.length,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = results[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  close(context, null);
                  if (item['screen'] == null) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => item['screen']));
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.modernPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(item['icon'], color: AppColors.modernPrimary, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Click to open ${item['title']}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade200, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
