import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vps/features/common/widgets/modern_layout.dart';
import 'package:vps/core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vps/data/services/attendance_service.dart';
import 'package:vps/data/services/user_service.dart';
import 'package:vps/data/services/fee_service.dart';
import 'package:vps/data/models/attendance_record.dart';
import 'package:rxdart/rxdart.dart';

import 'package:vps/data/services/strategic_planning_service.dart';
import 'package:vps/data/models/strategic_task.dart';

class StrategicPlanningScreen extends StatefulWidget {
  const StrategicPlanningScreen({Key? key}) : super(key: key);

  @override
  State<StrategicPlanningScreen> createState() => _StrategicPlanningScreenState();
}

class _StrategicPlanningScreenState extends State<StrategicPlanningScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Stream<List<StrategicTask>>? _currentTasksStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now(); // Default to now
    _updateTasksStream();
  }

  void _updateTasksStream() {
    // Check if context is valid (mounted)
    if (!mounted) return;
    _currentTasksStream = Provider.of<StrategicPlanningService>(context, listen: false).getActiveTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTasksStream == null) {
      _selectedDay ??= DateTime.now();
      _updateTasksStream();
    }
    return ModernLayout(
      title: 'Strategic Planning & Operations',
      child: StreamBuilder<List<StrategicTask>>(
        stream: _currentTasksStream,
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKPIHeader(),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Central Planning Hub (Calendar)
                    Expanded(
                      flex: 5,
                      child: _buildPlanningHub(allTasks),
                    ),
                    const SizedBox(width: 24),
                    // Column 2 & 3: Kanban & Action Center
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildKanbanBoard(allTasks),
                          const SizedBox(height: 24),
                          _buildActionCenter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildKPIHeader() {
    return Row(
      children: [
        // 1. Daily Attendance (Students)
        Expanded(
          child: StreamBuilder<Map<String, int>>(
            stream: Provider.of<AttendanceService>(context).getDailyAttendanceSummaryStream(DateTime.now()),
            builder: (context, snapshot) {
               // We need total students count to calculate percentage
               return StreamBuilder<List<Map<String, dynamic>>>(
                 stream: Provider.of<UserService>(context).getAllStudents(),
                 builder: (context, studentSnapshot) {
                    int present = snapshot.data?['present'] ?? 0;
                    int total = studentSnapshot.data?.length ?? 1; // Avoid div/0
                    if (total == 0) total = 1;

                    double percentage = (present / total);
                    String display = "${(percentage * 100).toStringAsFixed(0)}%";
                    
                    if (snapshot.connectionState == ConnectionState.waiting || studentSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildKPICard('Daily Attendance', '...', Icons.people_outline, Colors.blue, 0.0);
                    }

                    return _buildKPICard('Daily Attendance', '$display ($present/$total)', Icons.people_outline, Colors.blue, percentage);
                 }
               );
            }
          ),
        ),
        const SizedBox(width: 16),
        
        // 2. Teacher Availability
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Provider.of<UserService>(context).getTeachers(),
            builder: (context, teacherSnapshot) {
              return FutureBuilder<AttendanceRecord?>(
                future: Provider.of<AttendanceService>(context).getAttendance('TEACHERS', DateTime.now()),
                builder: (context, attendanceSnapshot) {
                   int totalTeachers = teacherSnapshot.data?.length ?? 1;
                   if (totalTeachers == 0) totalTeachers = 1;
                   
                   int presentTeachers = 0;
                   if (attendanceSnapshot.hasData && attendanceSnapshot.data != null) {
                      var records = attendanceSnapshot.data!.attendance;
                      presentTeachers = records.values.where((v) => v == 'Present').length;
                   } else {
                     // If no record found for today yet, assume 0 or check if it's because un-marked
                     // For dashboard, 0 is safer until marked
                     presentTeachers = 0;
                   }

                   double percentage = presentTeachers / totalTeachers;
                   
                   if (teacherSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildKPICard('Teacher Availability', '...', Icons.school_outlined, Colors.teal, 0.0);
                   }

                   return _buildKPICard('Teacher Availability', '$presentTeachers/$totalTeachers', Icons.school_outlined, Colors.teal, percentage);
                }
              );
            }
          ),
        ),
        const SizedBox(width: 16),

        // 3. Budget Health (Collection vs Expected)
        Expanded(
          child: FutureBuilder<Map<String, double>>(
            future: Provider.of<FeeService>(context).getMonthFeeStats(DateFormat('MMMM').format(DateTime.now())),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                 return _buildKPICard('Budget Health', '...', Icons.account_balance_wallet_outlined, Colors.orange, 0.0);
              }
              
              double collected = snapshot.data?['collected'] ?? 0.0;
              double expected = snapshot.data?['expected'] ?? 1.0;
              if (expected == 0) expected = 1; // Avoid div/0

              double percentage = (collected / expected).clamp(0.0, 1.0);
              String percentageDisplay = "${(percentage * 100).toStringAsFixed(0)}%";
              
              // Format simply like '82%' or '45k/50k' if space allows. Keeping it simple '82%' as per original design, 
              // or maybe '82% (45k)'
              String displayValue = "$percentageDisplay";

              return _buildKPICard('Budget Health', displayValue, Icons.account_balance_wallet_outlined, Colors.orange, percentage);
            }
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, double progress) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningHub(List<StrategicTask> allTasks) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scheduler',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                _buildLegend(),
              ],
            ),
            const SizedBox(height: 24),
            TableCalendar<StrategicTask>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    // No need to update stream, we filter on client side now
                  });
                }
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                markersMaxCount: 3, // Show multiple dots if needed
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              eventLoader: (day) {
                return allTasks.where((task) => isSameDay(task.date, day)).toList();
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((event) {
                      Color color = Colors.blue; // Normal
                      if (event.priority == 'High') color = Colors.orange;
                      if (event.priority == 'Urgent') color = Colors.red;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        width: 7,
                        height: 7,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
             const SizedBox(height: 16),
             Center(
               child: ElevatedButton.icon(
                 onPressed: () => _showAddTaskDialog(),
                 icon: Icon(Icons.add),
                 label: Text('Plan Task for ${_selectedDay?.day ?? DateTime.now().day}/${_selectedDay?.month ?? DateTime.now().month}'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.blue,
                   foregroundColor: Colors.white,
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String priority = 'Normal';
    String column = 'To Do';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Task for ${_selectedDay?.toString().split(" ")[0] ?? DateTime.now().toString().split(" ")[0]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Task Title'),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: priority,
              items: ['Normal', 'High', 'Urgent'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => priority = val!,
              decoration: InputDecoration(labelText: 'Priority'),
            ),
            SizedBox(height: 16),
             DropdownButtonFormField<String>(
              value: column,
              items: ['To Do', 'In Progress'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => column = val!,
              decoration: InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                 Provider.of<StrategicPlanningService>(context, listen: false).addTask(
                   titleController.text,
                   _selectedDay ?? DateTime.now(),
                   priority,
                   column,
                 );
                 Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem('Urgent', Colors.red),
        const SizedBox(width: 12),
        _legendItem('High', Colors.orange),
        const SizedBox(width: 12),
        _legendItem('Normal', Colors.blue),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildKanbanBoard(List<StrategicTask> allTasks) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Administrative Priorities',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                 TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreviousWorkScreen())),
                  child: Text('See Previous Work'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                // Filter client side
                final selectedDateStart = DateTime(_selectedDay?.year ?? DateTime.now().year, _selectedDay?.month ?? DateTime.now().month, _selectedDay?.day ?? DateTime.now().day);
                final selectedDateEnd = selectedDateStart.add(Duration(days: 1));

                final tasks = allTasks.where((t) {
                   return t.date.isAfter(selectedDateStart.subtract(Duration(seconds: 1))) && 
                          t.date.isBefore(selectedDateEnd);
                }).toList();

                final todo = tasks.where((t) => t.column == 'To Do').toList();
                final inProgress = tasks.where((t) => t.column == 'In Progress').toList();
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildKanbanColumn('To Do', Colors.orange, todo)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKanbanColumn('In Progress', Colors.blue, inProgress)),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(String title, Color color, List<StrategicTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
              SizedBox(width: 8),
              Text('${tasks.length}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty) 
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No tasks", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          
        ...tasks.map((task) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Checkbox(
                     value: task.isCompleted, 
                     onChanged: (val) {
                       if (val == true) {
                         Provider.of<StrategicPlanningService>(context, listen: false).toggleTaskCompletion(task.id, true);
                       }
                     },
                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                   ),
                   Expanded(child: Text(task.title, style: GoogleFonts.inter(fontSize: 12, color: Colors.black87))),
                ],
              ),
              if (task.priority != 'Normal')
                 Container(
                   margin: EdgeInsets.only(left: 4),
                   padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                   child: Text(task.priority, style: TextStyle(fontSize: 10, color: Colors.red)),
                 ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildActionCenter() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Center',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _actionTile('Approve Pending Leaves', Icons.assignment_turned_in_outlined, Colors.orange),
            _actionTile('Send Emergency Broadcast', Icons.campaign_outlined, Colors.red),
            _actionTile('Generate Performance Report', Icons.analytics_outlined, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: () {},
    );
  }
}

class PreviousWorkScreen extends StatefulWidget {
  @override
  _PreviousWorkScreenState createState() => _PreviousWorkScreenState();
}

class _PreviousWorkScreenState extends State<PreviousWorkScreen> {
  Stream<List<StrategicTask>>? _completedTasksStream;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  void _fetchTasks() {
    if (!mounted) return;
    _completedTasksStream = Provider.of<StrategicPlanningService>(context, listen: false).getCompletedTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (_completedTasksStream == null) {
      _fetchTasks();
    }
    return ModernLayout(
      title: 'Previous Strategic Work',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Completed Tasks History", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<StrategicTask>>(
                stream: _completedTasksStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                  final tasks = snapshot.data ?? [];
                  
                  // Sort client side
                  tasks.sort((a, b) => b.date.compareTo(a.date));

                  if (tasks.isEmpty) return Center(child: Text("No completed work found"));
                  
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(Icons.check_circle, color: Colors.green),
                          title: Text(task.title, style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                          subtitle: Text("Completed on: ${task.date.toString().split(' ')[0]}"),
                          trailing: Container(
                             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                             child: Text("Done", style: TextStyle(color: Colors.green, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
