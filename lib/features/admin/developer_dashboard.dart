import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../data/services/user_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/school_info_service.dart';
import 'dev_school_info_screen.dart';
import 'package:intl/intl.dart';

class DeveloperDashboard extends StatefulWidget {
  const DeveloperDashboard({super.key});

  @override
  State<DeveloperDashboard> createState() => _DeveloperDashboardState();
}

class _DeveloperDashboardState extends State<DeveloperDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Color(0xFF0F172A), // Slate 900
      body: Stack(
        children: [
          // Dynamic Background Blobs
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlob(400, Color(0xFF3B82F6).withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlob(300, Color(0xFF8B5CF6).withOpacity(0.15)),
          ),
          
          Row(
            children: [
              _buildSidebar(context, authService),
              Expanded(
                child: SafeArea(
                  child: _selectedIndex == 0 
                      ? _buildMetricsDashboard(context, userService, authService)
                      : const DevSchoolInfoScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AuthService authService) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.terminal, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 12),
                Text(
                  'DEV_OPS',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          _buildSidebarItem(
            icon: Icons.dashboard,
            title: 'Live Metrics',
            index: 0,
          ),
          _buildSidebarItem(
            icon: Icons.account_balance,
            title: 'School Configs',
            index: 1,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildLogoutButton(context, authService),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.blueGrey.shade400, size: 20),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.blueAccent : Colors.blueGrey.shade300,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMetricsDashboard(BuildContext context, UserService userService, AuthService authService) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        final users = snapshot.data ?? [];
        
        // Real-time counting
        int studentCount = users.where((u) => u['role'] == 'student').length;
        int teacherCount = users.where((u) => u['role'] == 'teacher').length;
        int staffCount = users.where((u) => (u['role'] == 'staff' || u['role'] == 'driver' || u['role'] == 'management')).length;
        int adminCount = users.where((u) => u['role'] == 'admin').length;
        int principalCount = users.where((u) => u['role'] == 'principal').length;
        int totalUsers = users.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Developer Analysis",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Live School Metrics & Verification",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.blue.shade200,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // NEW: GLOBAL SYSTEM LOCK TOGGLE
              StreamBuilder<Map<String, dynamic>?>(
                stream: Provider.of<SchoolInfoService>(context).getSchoolInfoStream(),
                builder: (context, snapshot) {
                  final info = snapshot.data ?? {};
                  final isLocked = info['isAppLocked'] == true;
                  
                  return _buildGlassCard(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                              color: isLocked ? Colors.redAccent : Colors.greenAccent,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "GLOBAL SYSTEM LOCK",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isLocked 
                                    ? "Emergency Lockdown Active. All non-student users are blocked."
                                    : "System is running normally. All users have access.",
                                  style: GoogleFonts.outfit(
                                    color: Colors.blueGrey.shade300,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isLocked,
                            activeColor: Colors.redAccent,
                            onChanged: (val) async {
                              try {
                                await Provider.of<SchoolInfoService>(context, listen: false)
                                    .updateSchoolInfo({'isAppLocked': val});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(val ? "SYSTEM LOCKED" : "SYSTEM UNLOCKED"),
                                    backgroundColor: val ? Colors.red : Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Action failed: $e")),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // NEW: SCHEDULED LOCKOUT PICKER
              StreamBuilder<Map<String, dynamic>?>(
                stream: Provider.of<SchoolInfoService>(context).getSchoolInfoStream(),
                builder: (context, snapshot) {
                  final info = snapshot.data ?? {};
                  final isScheduled = info['isLockoutScheduled'] == true;
                  final scheduledTime = info['scheduledLockoutTime'] != null 
                      ? (info['scheduledLockoutTime'] as dynamic).toDate() as DateTime 
                      : null;
                  
                  return _buildGlassCard(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                "SCHEDULE SYSTEM LOCK",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (isScheduled)
                                TextButton.icon(
                                  onPressed: () async {
                                    await Provider.of<SchoolInfoService>(context, listen: false)
                                        .updateSchoolInfo({
                                      'isLockoutScheduled': false,
                                      'scheduledLockoutTime': null,
                                    });
                                  },
                                  icon: Icon(Icons.cancel, color: Colors.redAccent, size: 16),
                                  label: Text("Clear Schedule", style: TextStyle(color: Colors.redAccent)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (isScheduled && scheduledTime != null)
                             Container(
                               padding: EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: Colors.orangeAccent.withOpacity(0.05),
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
                               ),
                               child: Row(
                                 children: [
                                   Icon(Icons.notifications_active, color: Colors.orangeAccent, size: 20),
                                   const SizedBox(width: 12),
                                   Text(
                                     "Lockout at: ${DateFormat('MMM dd, yyyy - hh:mm a').format(scheduledTime)}",
                                     style: GoogleFonts.outfit(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                                   ),
                                 ],
                               ),
                             )
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    final finalDateTime = DateTime(
                                      date.year, date.month, date.day,
                                      time.hour, time.minute,
                                    );
                                    await Provider.of<SchoolInfoService>(context, listen: false)
                                        .updateSchoolInfo({
                                      'isLockoutScheduled': true,
                                      'scheduledLockoutTime': finalDateTime,
                                    });
                                  }
                                }
                              },
                              icon: Icon(Icons.add_alarm, size: 18),
                              label: Text("Set Lockout Schedule"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                foregroundColor: Colors.blueAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            "Admins & Principals will see a warning reminder until this time.",
                            style: GoogleFonts.outfit(color: Colors.blueGrey.shade400, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ),

              const SizedBox(height: 32),
              
              // Total Users Large Card
              _buildGlassCard(
                width: double.infinity,
                height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "TOTAL USERS",
                      style: GoogleFonts.outfit(
                        color: Colors.blueGrey.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      totalUsers.toString(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPulsingDot(Colors.greenAccent),
                          const SizedBox(width: 8),
                          Text(
                            "REALTIME SYNCED",
                            style: GoogleFonts.outfit(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Text(
                "ROLE DISTRIBUTION",
                style: GoogleFonts.outfit(
                  color: Colors.blueGrey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Metrics Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildMetricCard("Students", studentCount, Icons.school, Colors.blue),
                    _buildMetricCard("Teachers", teacherCount, Icons.person, Colors.purple),
                    _buildMetricCard("Staff", staffCount, Icons.badge, Colors.orange),
                    _buildMetricCard("Admins", adminCount, Icons.admin_panel_settings, Colors.red),
                    _buildMetricCard("Principals", principalCount, Icons.account_balance, Colors.teal),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, int count, IconData icon, Color color) {
    return _buildGlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({double? width, double? height, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildPulsingDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return InkWell(
      onTap: () => authService.signOut(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              "EXIT",
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
