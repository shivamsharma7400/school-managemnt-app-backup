
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/routine_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/school_info_service.dart';
import '../../data/services/time_table_pdf_service.dart';
import '../../data/services/bus_routine_service.dart';
import '../../data/services/user_service.dart';
import '../../core/constants/app_constants.dart';
import 'dart:ui';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class RoutineViewScreen extends StatelessWidget {
  const RoutineViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isStudent = authService.role == 'student';
    final feeConfig = authService.currentUserData?['feeConfig'] as Map<String, dynamic>? ?? {};
    final bool showBusTab = !isStudent || (feeConfig['Bus Fee'] == true);

    return DefaultTabController(
      length: showBusTab ? 3 : 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          title: const Text('School Routines', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF4F46E5),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Class', icon: Icon(Icons.class_outlined, size: 20)),
              if (showBusTab) Tab(text: 'Bus', icon: Icon(Icons.directions_bus_outlined, size: 20)),
              Tab(text: 'Timetable', icon: Icon(Icons.table_chart_outlined, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RoutineList(type: 'class'),
            if (showBusTab) _RoutineList(type: 'bus'),
            _RoutineList(type: 'timetable'),
          ],
        ),
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  final String type;

  const _RoutineList({required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == 'bus') {
      return const _BusRoutineTab();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<RoutineService>(context).getRoutines(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final authService = Provider.of<AuthService>(context, listen: false);
        final isStudent = authService.role == 'student';
        final classId = authService.currentUserData?['classId'];

        var routines = snapshot.data ?? [];

        // Filter for students: Only show their specific class routine
        if (isStudent && type == 'class' && classId != null) {
          routines = routines.where((r) {
            final title = (r['title'] ?? '').toString().toLowerCase();
            return title.contains('class $classId'.toLowerCase());
          }).toList();
        }

        if (routines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.event_busy_outlined, size: 64, color: Colors.indigo.shade200),
                ),
                const SizedBox(height: 24),
                Text(
                  isStudent && type == 'class' 
                      ? 'No routine for Class $classId yet' 
                      : 'No routines found',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check back later or contact admin.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<Map<String, dynamic>?>(
          stream: Provider.of<SchoolInfoService>(context, listen: false).getSchoolInfoStream(),
          builder: (context, infoSnapshot) {
            final info = infoSnapshot.data ?? {};
            
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                final bool isClass = type == 'class';
                final bool isTimeTable = type == 'timetable';
                
                if (isStudent && (isClass || isTimeTable)) {
                  final bool allowDownload = isClass 
                      ? (info['allowRoutineDownload'] ?? false)
                      : (info['allowTimeTableDownload'] ?? false);
                      
                  return _buildPremiumDownloadCard(
                    context, 
                    routine, 
                    allowDownload, 
                    isClass ? "Class $classId" : (routine['title'] ?? "Exam Schedule"),
                    isClass ? Icons.auto_stories_rounded : Icons.assignment_rounded,
                    isClass ? "Scheduled Classes" : "Exam Timing",
                    isClass ? "Mon - Sat" : "Session 2024-25"
                  );
                }

                return _buildStandardRoutineCard(context, routine, type);
              },
            );
          }
        );
      },
    );
  }

  Widget _buildPremiumDownloadCard(
    BuildContext context, 
    Map<String, dynamic> routine, 
    bool allowDownload, 
    String headerTitle,
    IconData headerIcon,
    String infoLabel,
    String infoValue
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.indigo.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(headerIcon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            "Academic Session 2024-25",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Divider(height: 1),
              ),
              
              // Info Grid
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.calendar_month_outlined, infoLabel, infoValue),
                    const SizedBox(height: 20),
                    _buildInfoRow(Icons.update_rounded, "Last Updated", "Today, 09:30 AM"),
                    const SizedBox(height: 20),
                    _buildInfoRow(Icons.verified_user_outlined, "Approved By", "School Principal"),
                  ],
                ),
              ),

              // Action Area
              if (allowDownload && routine['tableData'] != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        TimeTablePdfService.generateBulk(
                          schoolName: AppStrings.appName,
                          address: AppStrings.schoolAddress,
                          routines: [routine],
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_for_offline_rounded, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "Download PDF Format",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (!allowDownload)
                Container(
                  margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Downloads are currently restricted by management.",
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStandardRoutineCard(BuildContext context, Map<String, dynamic> routine, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            title: Text(
              routine['title'] ?? '', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))
            ),
            subtitle: routine['tableData'] == null ? Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SelectableLinkify(
                onOpen: (link) async {
                   final Uri url = Uri.parse(link.url);
                   if (await canLaunchUrl(url)) {
                     await launchUrl(url, mode: LaunchMode.externalApplication);
                   }
                },
                text: routine['description'] ?? '',
                style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
                linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ) : null,
            trailing: routine['imageUrl'] != null && (routine['imageUrl'] as String).isNotEmpty
                ? InkWell(
                    onTap: () => _showFullScreenImage(context, routine['imageUrl']),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(routine['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                : null,
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: Icon(
                type == 'class' 
                    ? Icons.book 
                    : type == 'bus' 
                        ? Icons.airport_shuttle 
                        : Icons.table_chart, 
                color: Colors.indigo,
                size: 20,
              ),
            ),
          ),
          if (routine['tableData'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50.withOpacity(0.5)),
                      dataRowHeight: 56,
                      columnSpacing: 20,
                      columns: List<String>.from(routine['tableData']['columns'] ?? [])
                          .map((c) => DataColumn(
                                label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12)),
                              ))
                          .toList(),
                      rows: (routine['tableData']['rows'] as List? ?? [])
                          .map((row) {
                            final List<dynamic> cells = (row is Map)
                                ? List.generate(
                                    (routine['tableData']['columns'] as List).length,
                                    (i) => row[i.toString()] ?? "",
                                  )
                                : (row as List);

                            return DataRow(
                              cells: cells.asMap().entries.map((cellEntry) {
                                return DataCell(
                                  Text(
                                    cellEntry.value.toString(),
                                    style: TextStyle(
                                      fontWeight: cellEntry.key == 0 ? FontWeight.bold : FontWeight.normal,
                                      color: cellEntry.key == 0 ? Colors.indigo.shade700 : const Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusRoutineTab extends StatelessWidget {
  const _BusRoutineTab();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isStudent = authService.role == 'student';
    final busStopId = authService.currentUserData?['busStopId']?.toString();

    return StreamBuilder<List<BusRoutine>>(
      stream: Provider.of<BusRoutineService>(context).getAllRoutinesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var routines = snapshot.data ?? [];

        // For students, filter by their bus stop
        if (isStudent && busStopId != null) {
          routines = routines.where((r) {
            return r.stops.any((s) => s.stopId == busStopId);
          }).toList();
        }

        if (routines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_bus_outlined, size: 64, color: Colors.indigo.shade200),
                ),
                const SizedBox(height: 24),
                Text(
                  isStudent ? 'No bus routine for your stop yet' : 'No bus routines found',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];
            if (isStudent && busStopId != null) {
              final studentStop = routine.stops.firstWhere((s) => s.stopId == busStopId);
              return _buildStudentBusRoutineCard(context, routine, studentStop);
            }
            return _buildPremiumBusCard(context, routine);
          },
        );
      },
    );
  }

  Widget _buildStudentBusRoutineCard(BuildContext context, BusRoutine routine, BusRoutineStop studentStop) {
    final isArrival = routine.type == 'Arrival';
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isArrival ? Colors.green : Colors.indigo).withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: (isArrival ? Colors.green : Colors.indigo).withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Header with Trip and Type
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isArrival 
                    ? [const Color(0xFF059669), const Color(0xFF10B981)] 
                    : [const Color(0xFF4F46E5), const Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isArrival ? Icons.bus_alert_rounded : Icons.departure_board_rounded,
                    color: Colors.white,
                    size: 28
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, dynamic>?>(
                        future: Provider.of<UserService>(context, listen: false).getUserData(routine.driverId),
                        builder: (context, snapshot) {
                          final driverName = snapshot.data?['name'] ?? 'Loading...';
                          return Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                      ),
                      Row(
                        children: [
                          Text(
                            "${routine.type} Schedule",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                          ),
                          Text(
                            "Trip #${routine.tripNumber}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    "T-${routine.tripNumber}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Info Area
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Stop Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isArrival ? Colors.green : Colors.indigo).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded, 
                        color: isArrival ? Colors.green : Colors.indigo,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "YOUR BUS STOP",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            studentStop.stopName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),
                // Timing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SCHEDULED TIME",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 18, color: isArrival ? Colors.green : Colors.indigo),
                            const SizedBox(width: 8),
                            Text(
                              studentStop.time,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isArrival ? Colors.green.shade700 : Colors.indigo.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: (isArrival ? Colors.green : Colors.indigo).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isArrival ? "PICKUP" : "DROP",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isArrival ? Colors.green.shade800 : Colors.indigo.shade800,
                              letterSpacing: 1,
                            ),
                          ),
                          Icon(isArrival ? Icons.north_east_rounded : Icons.south_west_rounded, 
                            size: 16, 
                            color: isArrival ? Colors.green : Colors.indigo
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBusCard(BuildContext context, BusRoutine routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: routine.type == 'Arrival' 
                    ? [const Color(0xFF059669), const Color(0xFF10B981)] 
                    : [const Color(0xFF4F46E5), const Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    routine.type == 'Arrival' ? Icons.login_rounded : Icons.logout_rounded,
                    color: Colors.white,
                    size: 24
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, dynamic>?>(
                        future: Provider.of<UserService>(context, listen: false).getUserData(routine.driverId),
                        builder: (context, snapshot) {
                          final driverName = snapshot.data?['name'] ?? '...';
                          return Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }
                      ),
                      Text(
                        "${routine.type} | Trip #${routine.tripNumber}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "STOPS & TIMINGS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ...routine.stops.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final stop = entry.value;
                  final isLast = idx == routine.stops.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: idx == 0 ? Colors.green : (isLast ? Colors.red : Colors.indigo),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: (idx == 0 ? Colors.green : (isLast ? Colors.red : Colors.indigo)).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: Colors.indigo.withOpacity(0.1),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stop.stopName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    stop.time,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
