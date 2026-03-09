import 'package:flutter/material.dart';
import 'package:vps/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:vps/data/services/attendance_service.dart';
import 'package:vps/data/services/user_service.dart';
import 'package:vps/data/services/fee_service.dart';
import 'package:vps/data/models/attendance_record.dart';
import 'package:intl/intl.dart';
import 'package:vps/data/services/class_service.dart';
import 'package:vps/data/models/class_model.dart';
import 'package:vps/features/student/student_bus_tracker_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vps/features/principal/user_management_screen.dart';
import 'package:rxdart/rxdart.dart';


class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final double? trend;
  final VoidCallback? onTap;

  const MetricCard({super.key, 
    required this.title,
    required this.value,
    this.subtitle = '',
    required this.icon,
    required this.iconColor,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  if (trend != null)
                    Row(
                      children: [
                        Icon(
                          trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: trend! >= 0 ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${trend!.abs()}%',
                          style: GoogleFonts.outfit(
                            color: trend! >= 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          subtitle,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    )
                  else if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const ActionCard({super.key, 
    required this.title,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String date;
  final String type;

  const AnnouncementCard({super.key, 
    required this.title,
    required this.date,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;
    Color bgColor;

    switch (type.toLowerCase()) {
      case 'urgent':
        iconColor = Colors.red;
        icon = Icons.warning_amber_rounded;
        bgColor = Colors.red.shade50;
        break;
      case 'event':
        iconColor = Colors.purple;
        icon = Icons.event;
        bgColor = Colors.purple.shade50;
        break;
      case 'progress':
        iconColor = Colors.blue;
        icon = Icons.trending_up;
        bgColor = Colors.blue.shade50;
        break;
      default:
        iconColor = Colors.blue;
        icon = Icons.campaign_outlined;
        bgColor = Colors.blue.shade50;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          if (type == 'progress')
            Container(
              height: 20,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AttendancePieChartCard extends StatelessWidget {
  const AttendancePieChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final attendanceService = Provider.of<AttendanceService>(context, listen: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today Attendance',
                  style: GoogleFonts.outfit(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.analytics_outlined, size: 18, color: AppColors.modernPrimary),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: Rx.combineLatest2(
                  userService.getAllStudents(),
                  attendanceService.getDailyAttendanceSummaryStream(DateTime.now()),
                  (List<Map<String, dynamic>> students, Map<String, int> summary) {
                    return {
                      'totalStudents': students.length,
                      'present': summary['present'] ?? 0,
                      'absent': summary['absent'] ?? 0,
                      'totalMarked': summary['totalMarked'] ?? 0,
                    };
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }

                  final data = snapshot.data ?? {'totalStudents': 0, 'present': 0, 'absent': 0, 'totalMarked': 0};
                  final totalStudents = data['totalStudents'] as int;
                  final presentCount = data['present'] as int;
                  final absentCount = data['absent'] as int;
                  final totalMarked = data['totalMarked'] as int;
                  final pendingCount = (totalStudents - totalMarked).clamp(0, totalStudents);

                  return Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 25,
                                sections: [
                                  if (presentCount > 0)
                                    PieChartSectionData(
                                      value: presentCount.toDouble(),
                                      color: Colors.green,
                                      radius: 30,
                                      showTitle: false,
                                    ),
                                  if (absentCount > 0)
                                    PieChartSectionData(
                                      value: absentCount.toDouble(),
                                      color: Colors.red,
                                      radius: 30,
                                      showTitle: false,
                                    ),
                                  if (pendingCount > 0)
                                    PieChartSectionData(
                                      value: pendingCount.toDouble(),
                                      color: Colors.orange.withOpacity(0.6),
                                      radius: 30,
                                      showTitle: false,
                                    ),
                                  if (totalStudents == 0)
                                    PieChartSectionData(
                                      value: 1,
                                      color: Colors.grey.shade300,
                                      radius: 30,
                                      showTitle: false,
                                    ),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    totalStudents.toString(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  const Text(
                                    'Total',
                                    style: TextStyle(fontSize: 8, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem('Present', presentCount.toString(), Colors.green),
                            _buildLegendItem('Absent', absentCount.toString(), Colors.red),
                            _buildLegendItem('Pending', pendingCount.toString(), Colors.orange),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 6),
          Text('$label:', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
        ],
      ),
    );
  }
}

class FeeCollectionMetricCard extends StatefulWidget {
  const FeeCollectionMetricCard({super.key});

  @override
  _FeeCollectionMetricCardState createState() => _FeeCollectionMetricCardState();
}

class _FeeCollectionMetricCardState extends State<FeeCollectionMetricCard> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final feeService = Provider.of<FeeService>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee Collection Today',
                  style: GoogleFonts.outfit(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                ),
              ],
            ),
            StreamBuilder<double>(
              stream: feeService.getTodayFeeCollectionStream(),
              builder: (context, snapshot) {
                final amount = snapshot.data ?? 0.0;
                final isLoading = snapshot.connectionState == ConnectionState.waiting;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isLoading)
                          SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Text(
                            _currencyFormat.format(amount),
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onBackground,
                            ),
                          ),
                        // Refresh button still useful for forced sync if needed, though Stream is live
                        IconButton(
                          icon: Icon(Icons.sync, size: 18, color: Colors.grey.withOpacity(0.5)),
                          onPressed: () {}, // Stream will auto-refresh, but sync icon is visual cue
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      'Manual payments today',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BusStatusMapCard extends StatefulWidget {
  const BusStatusMapCard({super.key});

  @override
  _BusStatusMapCardState createState() => _BusStatusMapCardState();
}

class _BusStatusMapCardState extends State<BusStatusMapCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentBusTrackerScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bus Tracking',
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('bus_tracking').where('status', isEqualTo: 'active').snapshots(),
                    builder: (context, snapshot) {
                      bool isActive = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                      return Row(
                        children: [
                          if (isActive) ...[
                            FadeTransition(
                              opacity: _pulseController,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text('LIVE', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ] else 
                            Text('INACTIVE', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      );
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Row(
                         children: [
                           Container(
                             padding: EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.blue.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Icon(Icons.directions_bus, color: Colors.blue, size: 24),
                           ),
                           SizedBox(width: 12),
                           StreamBuilder<QuerySnapshot>(
                             stream: FirebaseFirestore.instance.collection('bus_tracking').where('status', isEqualTo: 'active').snapshots(),
                             builder: (context, snapshot) {
                               final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                               return Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     '$count Active',
                                     style: GoogleFonts.outfit(
                                       fontSize: 18,
                                       fontWeight: FontWeight.bold,
                                       color: AppColors.onBackground,
                                     ),
                                   ),
                                   Text('Buses running', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                 ],
                               );
                             },
                           ),
                         ],
                       ),
                       Icon(Icons.map_outlined, color: Colors.grey.withOpacity(0.5), size: 30),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Click to view live map',
                    style: TextStyle(color: AppColors.modernPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingApprovalsMetricCard extends StatelessWidget {
  const PendingApprovalsMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Approvals',
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_add, color: Colors.orange, size: 20),
                  ),
                ],
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: userService.getPendingUsers(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.length : 0;
                  final isLoading = snapshot.connectionState == ConnectionState.waiting;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isLoading)
                            SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            Text(
                              count.toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                            ),
                          if (count > 0)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Action Needed',
                                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'New registrations',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceStatusCard extends StatelessWidget {
  const AttendanceStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceService = Provider.of<AttendanceService>(context);
    final classService = Provider.of<ClassService>(context, listen: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Status',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                    Text(
                      'Real-time class completion',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.modernPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.playlist_add_check_rounded, color: AppColors.modernPrimary, size: 20),
                ),
              ],
            ),
            SizedBox(height: 20),
            StreamBuilder<List<AttendanceRecord>>(
              stream: attendanceService.getMarkedClassDetailsStream(DateTime.now()),
              builder: (context, attendanceSnapshot) {
                final records = attendanceSnapshot.data ?? [];
                
                return StreamBuilder<List<ClassModel>>(
                  stream: classService.getAllClasses(),
                  builder: (context, classSnapshot) {
                    if (classSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    
                    final classes = classSnapshot.data ?? [];
                    classes.sort((a, b) {
                      final indexA = AppConstants.schoolClasses.indexOf(a.name);
                      final indexB = AppConstants.schoolClasses.indexOf(b.name);
                      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
                      return a.name.compareTo(b.name);
                    });

                    // Add Teachers and Staff to the check list
                    final List<Map<String, dynamic>> allTargets = classes.map((c) => {
                      'id': c.id,
                      'name': c.name,
                      'type': 'class'
                    }).toList();
                    
                    allTargets.add({'id': 'TEACHERS', 'name': 'Teachers', 'type': 'staff'});
                    allTargets.add({'id': 'Drivers', 'name': 'Staff', 'type': 'staff'});

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisExtent: 60,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: allTargets.length,
                      itemBuilder: (context, index) {
                        final target = allTargets[index];
                        final record = records.firstWhere(
                          (r) => r.classId == target['id'], 
                          orElse: () => AttendanceRecord(id: '', classId: '', date: DateTime.now(), attendance: <String, String>{})
                        );
                        final isDone = record.id.isNotEmpty;

                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.withOpacity(0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDone ? Colors.green.withOpacity(0.2) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isDone ? Colors.green : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDone ? Colors.green : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: isDone 
                                    ? Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      target['name'],
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                                        color: isDone ? Colors.green.shade700 : Colors.black87,
                                      ),
                                    ),
                                    if (isDone && record.markedByName != null)
                                      Text(
                                        'By: ${record.markedByName}',
                                        style: TextStyle(fontSize: 9, color: Colors.green.shade600),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else if (!isDone)
                                      Text(
                                        'Pending',
                                        style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
