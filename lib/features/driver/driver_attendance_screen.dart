import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/attendance_service.dart';
import '../../data/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DriverAttendanceScreen extends StatefulWidget {
  const DriverAttendanceScreen({Key? key}) : super(key: key);

  @override
  _DriverAttendanceScreenState createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends State<DriverAttendanceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final driverId = Provider.of<AuthService>(context, listen: false).user?.uid;

    if (driverId == null) return const Scaffold(body: Center(child: Text("Error: No Driver ID")));

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: FutureBuilder<Map<DateTime, String>>(
        future: Provider.of<AttendanceService>(context).getStudentAttendanceHistory(driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final history = snapshot.data ?? {};
          final normalizedHistory = history.map((key, value) => MapEntry(DateTime(key.year, key.month, key.day), value));
          
          final sortedDates = normalizedHistory.keys.toList()..sort((a, b) => b.compareTo(a));

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
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildCalendarDay(day, normalizedHistory);
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
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedDates.length > 5 ? 5 : sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final status = normalizedHistory[date]!;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.orange),
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

  Widget _buildSummaryCard(int present, int total, double percentage) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      color: Colors.orange,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text("${percentage.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text("Attendance", style: TextStyle(color: Colors.white70)),
              ],
            ),
            Column(
              children: [
                Text("$present / $total", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text("Days Present", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, Map<DateTime, String> history, {bool isToday = false}) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final status = history[dateKey];
    
    Color bgColor = Colors.transparent;
    TextStyle textStyle = const TextStyle(color: Colors.black);

    if (status != null) {
      if (status == 'Present') {
        bgColor = Colors.green;
        textStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
      } else if (status == 'Absent') {
        bgColor = Colors.red;
        textStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
      } else if (status == 'Leave') {
        bgColor = Colors.orange;
        textStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
      }
    } else if (isToday) {
      bgColor = Colors.orange.withOpacity(0.3);
    }
    
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Text('${day.day}', style: textStyle),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem("Present", Colors.green),
        _buildLegendItem("Absent", Colors.red),
        _buildLegendItem("Leave", Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
