import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';

// Import target screens for redirection
import '../fees/fee_status_screen.dart';
import '../fees/fee_management_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../attendance/attendance_view_screen.dart';
import '../homework/homework_screen.dart';
import '../results/student_result_screen.dart';
import '../common/routine_view_screen.dart';
import '../driver/driver_attendance_screen.dart';
import '../fees/staff_salary_view_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Stream<List<Map<String, dynamic>>> _notificationStream;

  @override
  void initState() {
    super.initState();
    _refreshStream();
  }

  void _refreshStream() {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      _notificationStream = Provider.of<NotificationService>(
        context,
        listen: false,
      ).getUserNotifications(user.uid);
    } else {
      _notificationStream = Stream.value([]);
    }
  }

  void _handleNotificationClick(Map<String, dynamic> notification) {
    final String? type = notification['type']?.toString().toLowerCase();
    final String? title = notification['title']?.toString().toLowerCase();
    final String? body = notification['body']?.toString().toLowerCase();
    final authService = Provider.of<AuthService>(context, listen: false);
    final String role = authService.role ?? 'student';

    // 1. Redirection Logic based on Type or Keywords
    if (type == 'fee' || type == 'salary' || (title?.contains('fee') ?? false) || (title?.contains('salary') ?? false) || (body?.contains('payment') ?? false)) {
      if (role == 'student') {
        Get.to(() => FeeStatusScreen());
      } else if (role == 'management' || role == 'principal' || role == 'admin') {
        Get.to(() => FeeManagementScreen());
      } else if (role == 'teacher' || role == 'driver' || role == 'staff') {
        Get.to(() => StaffSalaryViewScreen());
      }
    } else if (type == 'attendance' || (title?.contains('attendance') ?? false) || (body?.contains('absent') ?? false)) {
      if (role == 'student') {
        Get.to(() => AttendanceViewScreen());
      } else if (role == 'teacher' || role == 'principal' || role == 'admin' || role == 'management') {
        Get.to(() => MarkAttendanceScreen());
      } else if (role == 'driver') {
        // Redirection to Driver Attendance if it exists (driver_dashboard uses DriverAttendanceScreen)
        // I'll need to import it or use a keyword check
        try {
           Get.to(() => DriverAttendanceScreen());
        } catch (e) {
           Get.to(() => MarkAttendanceScreen());
        }
      }
    }
 else if (type == 'homework' || type == 'assignment' || (title?.contains('homework') ?? false) || (body?.contains('assignment') ?? false)) {
      Get.to(() => HomeworkScreen());
    } else if (type == 'result' || (title?.contains('result') ?? false) || (title?.contains('marks') ?? false)) {
      Get.to(() => StudentResultScreen());
    } else if (type == 'routine' || type == 'timetable' || (title?.contains('routine') ?? false) || (title?.contains('time table') ?? false)) {
      Get.to(() => RoutineViewScreen());
    } else {
      // Default: show details if no specific route
      _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(notification['title'] ?? 'Notification'),
        content: Text(notification['body'] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(List<Map<String, dynamic>> notifications) async {
    final service = Provider.of<NotificationService>(context, listen: false);
    for (var n in notifications) {
      if (!(n['read'] ?? false)) {
        await service.markAsRead(n['id']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    if (user == null)
      return Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onBackground,
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notificationStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.any((n) => !(n['read'] ?? false))) {
                return IconButton(
                  icon: const Icon(Icons.done_all, color: AppColors.primary),
                  tooltip: 'Mark all as read',
                  onPressed: () => _markAllAsRead(snapshot.data!),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none_rounded, size: 80, color: Colors.blue.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "No notifications yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We'll notify you when something important arrives",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          final groupedNotifications = <String, List<Map<String, dynamic>>>{};
          for (var notification in notifications) {
            final Timestamp? timestamp = notification['date'] as Timestamp?;
            final dateStr = timestamp != null
                ? _getDateHeader(timestamp.toDate())
                : 'Recent';
            if (groupedNotifications[dateStr] == null) {
              groupedNotifications[dateStr] = [];
            }
            groupedNotifications[dateStr]!.add(notification);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: groupedNotifications.length,
            itemBuilder: (context, index) {
              String header = groupedNotifications.keys.elementAt(index);
              List<Map<String, dynamic>> items = groupedNotifications[header]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
                    child: Text(
                      header.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  ...items.map((notification) {
                    final bool isRead = notification['read'] ?? false;
                    final String id = notification['id'];
                    final String type = notification['type']?.toString().toLowerCase() ?? '';

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isRead)
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                        ],
                        border: Border.all(
                          color: !isRead ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: () {
                              if (!isRead) {
                                Provider.of<NotificationService>(context, listen: false).markAsRead(id);
                              }
                              _handleNotificationClick(notification);
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(type, isRead).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(type),
                                    color: _getNotificationColor(type, isRead),
                                    size: 24,
                                  ),
                                ),
                                if (!isRead)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              notification['title'] ?? 'No Title',
                              style: TextStyle(
                                fontWeight: !isRead ? FontWeight.bold : FontWeight.w500,
                                fontSize: 16,
                                color: !isRead ? AppColors.onBackground : Colors.grey[700],
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                notification['body'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                                if (notification['date'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      DateFormat('HH:mm').format((notification['date'] as Timestamp).toDate()),
                                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'fee': return Icons.account_balance_wallet_rounded;
      case 'attendance': return Icons.fact_check_rounded;
      case 'homework':
      case 'assignment': return Icons.assignment_rounded;
      case 'result': return Icons.emoji_events_rounded;
      case 'routine':
      case 'timetable': return Icons.calendar_today_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type, bool isRead) {
    if (isRead) return Colors.grey;
    switch (type) {
      case 'fee': return Colors.green;
      case 'attendance': return Colors.orange;
      case 'homework':
      case 'assignment': return Colors.blue;
      case 'result': return Colors.purple;
      case 'routine':
      case 'timetable': return Colors.teal;
      default: return AppColors.primary;
    }
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return 'Today';
    if (dateToCheck == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}
