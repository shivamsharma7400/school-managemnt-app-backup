import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/attendance_service.dart';
import '../../data/services/class_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/class_model.dart';
import '../../data/services/auth_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final int initialIndex;
  MarkAttendanceScreen({this.initialIndex = 0});

  @override
  _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;
  bool _isLoading = false;
  Map<String, String> _attendanceStatus = {};
  
  // Toggle for Principal/Management
  late TabController _tabController;
  bool _isTeacherMode = false;
  bool _isStaffMode = false;
  bool _canSwitchMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
    _checkModes(widget.initialIndex);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
         setState(() {
           _checkModes(_tabController.index);
           _selectedClassId = null; // Reset selection on switch
           _attendanceStatus.clear();
         });
      }
    });
  }

  void _checkModes(int index) {
      _isTeacherMode = index == 1;
      _isStaffMode = index == 2;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userRole = authService.role;
    _canSwitchMode = (userRole == 'principal' || userRole == 'management' || userRole == 'admin');

    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'),
        bottom: _canSwitchMode 
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: "Students"),
                  Tab(text: "Teachers"),
                  Tab(text: "Staff"),
                ],
              ) 
            : null,
      ),
      body: Column(
        children: [
          // 1. Details Section: Class & Date
          Card(
             margin: EdgeInsets.all(8),
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 children: [
                    if (!_isTeacherMode && !_isStaffMode) _buildClassDropdown(authService.user?.uid),
                    SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Date: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                           setState(() {
                             _selectedDate = picked;
                             _attendanceStatus.clear();
                           });
                        }
                      },
                    ),
                 ],
               ),
             ),
          ),
          
          Divider(),
          
          // 2. Student/Teacher List
          Expanded(
            child: _buildList(),
          ),

          // 3. Submit Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || (!_isTeacherMode && !_isStaffMode && _selectedClassId == null)) ? null : _submitAttendance,
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Submit Attendance'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown(String? teacherId) {
    return StreamBuilder<List<String>>(
      stream: Provider.of<AttendanceService>(context).getMarkedClassIdsStream(_selectedDate),
      builder: (context, markedSnapshot) {
        final markedClassIds = markedSnapshot.data ?? [];
        
        return StreamBuilder<List<ClassModel>>(
          stream: Provider.of<ClassService>(context).getAllClasses(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return LinearProgressIndicator();
            final classes = snapshot.data!;
            
            return DropdownButtonFormField<String>(
              value: _selectedClassId,
              decoration: InputDecoration(
                labelText: 'Select Class', 
                border: OutlineInputBorder(),
                helperText: 'Classes with checkmark (✓) have completed attendance.',
                helperStyle: TextStyle(color: Colors.green, fontSize: 10),
              ),
              items: classes.map((c) {
                final isDone = markedClassIds.contains(c.id);
                return DropdownMenuItem(
                  value: c.id, 
                  child: Row(
                    children: [
                      Text(c.name),
                      if (isDone) ...[
                        SizedBox(width: 8),
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ],
                    ],
                  )
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClassId = val;
                  _attendanceStatus.clear(); 
                });
              },
            );
          },
        );
      }
    );
  }

  Widget _buildList() {
    if (!_isTeacherMode && !_isStaffMode && _selectedClassId == null) {
      return Center(child: Text("Select a Class to view students"));
    }

    return StreamBuilder<List<String>>(
      stream: Provider.of<AttendanceService>(context).getMarkedClassIdsStream(_selectedDate),
      builder: (context, markedSnapshot) {
        final markedClassIds = markedSnapshot.data ?? [];
        final String currentTargetId;
        if (_isTeacherMode) currentTargetId = 'TEACHERS';
        else if (_isStaffMode) currentTargetId = 'Drivers';
        else currentTargetId = _selectedClassId ?? '';

        final bool isAlreadyMarked = markedClassIds.contains(currentTargetId);

        Stream<List<Map<String, dynamic>>> stream;
        if (_isTeacherMode) {
          stream = Provider.of<UserService>(context).getTeachers();
        } else if (_isStaffMode) {
          stream = Provider.of<UserService>(context).getDrivers();
        } else {
          stream = Provider.of<UserService>(context).getStudentsByClass(_selectedClassId!);
        }

        return Column(
          children: [
            if (isAlreadyMarked)
              Container(
                width: double.infinity,
                color: Colors.green.shade50,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Attendance already marked for this day', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                  
                  final users = snapshot.data ?? [];

                  if (users.isEmpty) return Center(child: Text("No records found."));

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final id = user['id'];
                      final name = user['name'] ?? 'Unknown';

                      // Default to Present if not set
                      if (!_attendanceStatus.containsKey(id)) {
                        _attendanceStatus[id] = 'Present';
                      }

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                          title: Text(name),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _statusIcon(id, 'Present', Icons.check_circle, Colors.green),
                              SizedBox(width: 16),
                              _statusIcon(id, 'Absent', Icons.cancel, Colors.red),
                              SizedBox(width: 16),
                              _statusIcon(id, 'Leave', Icons.info, Colors.orange),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _statusIcon(String userId, String status, IconData icon, Color color) {
    bool isSelected = _attendanceStatus[userId] == status;
    return InkWell(
      onTap: () => setState(() => _attendanceStatus[userId] = status),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? color : Colors.grey.shade300, size: 30),
          Text(status, style: TextStyle(fontSize: 10, color: isSelected ? color : Colors.grey)),
        ],
      ),
    );
  }

  void _submitAttendance() async {
    setState(() => _isLoading = true);
    final String classId;
    if (_isTeacherMode) {
       classId = 'TEACHERS';
    } else if (_isStaffMode) {
       classId = 'Drivers'; // Using 'Drivers' as ID for all non-teaching staff for now as per requirement
    } else {
       classId = _selectedClassId!;
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    await Provider.of<AttendanceService>(context, listen: false).markAttendance(
      classId,
      _selectedDate,
      _attendanceStatus,
      userId: authService.user?.uid,
      userName: authService.userName,
    );
    
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance Saved!')));
    Navigator.pop(context);
  }
}
