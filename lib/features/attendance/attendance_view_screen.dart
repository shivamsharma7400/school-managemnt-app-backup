import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/attendance_service.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceViewScreen extends StatefulWidget {
  @override
  _AttendanceViewScreenState createState() => _AttendanceViewScreenState();
}

class _AttendanceViewScreenState extends State<AttendanceViewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final studentId = Provider.of<AuthService>(context, listen: false).user?.uid;

    if (studentId == null) return Scaffold(body: Center(child: Text("Error: No Student ID")));

    return Scaffold(
      appBar: AppBar(title: Text('My Attendance')),
      body: FutureBuilder<Map<DateTime, String>>(
        future: Provider.of<AttendanceService>(context).getStudentAttendanceHistory(studentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          
          final history = snapshot.data ?? {};
          // Normalize dates to remove time part for easier comparison
          final normalizedHistory = history.map((key, value) => MapEntry(normalizeDate(key), value));
          
          final sortedDates = normalizedHistory.keys.toList()..sort((a, b) => b.compareTo(a)); // Descending

          // Calculate summary
          int total = normalizedHistory.length;
          int present = normalizedHistory.values.where((v) => v == 'Present').length;
          double percentage = total > 0 ? (present / total) * 100 : 0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 _buildSummaryCard(present, total, percentage),
                 
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                   child: Card(
                     elevation: 4,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     child: Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: TableCalendar(
                         firstDay: DateTime.utc(2025, 1, 1),
                         lastDay: DateTime.utc(2030, 12, 31),
                         focusedDay: _focusedDay,
                         selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                         onDaySelected: (selectedDay, focusedDay) {
                           setState(() {
                             _selectedDay = selectedDay;
                             _focusedDay = focusedDay;
                           });
                         },
                         onPageChanged: (focusedDay) {
                           _focusedDay = focusedDay;
                         },
                         calendarBuilders: CalendarBuilders(
                           defaultBuilder: (context, day, focusedDay) {
                             return _buildCalendarDay(day, normalizedHistory);
                           },
                           selectedBuilder: (context, day, focusedDay) {
                             return _buildCalendarDay(day, normalizedHistory, isSelected: true);
                           },
                           todayBuilder: (context, day, focusedDay) {
                              return _buildCalendarDay(day, normalizedHistory, isToday: true);
                           },
                         ),
                       ),
                     ),
                   ),
                 ),
                 
                 Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: _buildLegend(),
                 ),
                 
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                   child: Text("Recent History", style: Theme.of(context).textTheme.titleMedium),
                 ),

                 ListView.builder(
                   shrinkWrap: true,
                   physics: NeverScrollableScrollPhysics(),
                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   itemCount: sortedDates.length > 5 ? 5 : sortedDates.length, // Show only recent 5
                   itemBuilder: (context, index) {
                     final date = sortedDates[index];
                     final status = normalizedHistory[date]!;
                     return Card(
                       margin: EdgeInsets.only(bottom: 8),
                       child: ListTile(
                         leading: Icon(Icons.calendar_today, color: AppColors.primary),
                         title: Text(DateFormat('EEEE, d MMM y').format(date)),
                         trailing: Chip(
                           label: Text(status),
                           backgroundColor: _getStatusColor(status),
                         ),
                       ),
                     );
                   },
                 ),
              ],
            ),
          );
        },
      ),
    );
  }

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Widget _buildCalendarDay(DateTime day, Map<DateTime, String> history, {bool isSelected = false, bool isToday = false}) {
      final dateKey = normalizeDate(day);
      final status = history[dateKey];
      
      Color bgColor = Colors.transparent;
      TextStyle textStyle = TextStyle(color: Colors.black);

      if (status != null) {
        if (status == 'Present') {
          bgColor = Colors.green;
          textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
        } else if (status == 'Absent') {
          bgColor = Colors.red;
          textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
        } else if (status == 'Leave') {
          bgColor = Colors.orange;
          textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
        }
      } else if (isToday) {
         bgColor = Colors.blue.withOpacity(0.3);
      }
      
      return Container(
        margin: EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle, // Or BoxShape.rectangle with borderRadius
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Text(
          '${day.day}',
          style: textStyle,
        ),
      );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem("Present", Colors.green),
        _buildLegendItem("Absent", Colors.red),
        _buildLegendItem("Leave", Colors.orange),
        _buildLegendItem("No Data", Colors.grey.shade200, textColor: Colors.black),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, {Color textColor = Colors.white}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16, 
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildSummaryCard(int present, int total, double percentage) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Attendance", style: TextStyle(color: Colors.white70)),
              ],
            ),
            Column(
              children: [
                Text("$present / $total", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Days Present", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present': return Colors.green.shade100;
      case 'Absent': return Colors.red.shade100;
      case 'Leave': return Colors.orange.shade100;
      default: return Colors.grey.shade100;
    }
  }
}
