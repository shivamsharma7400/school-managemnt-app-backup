
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../data/services/routine_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/school_config_service.dart';
import '../../data/services/class_service.dart';
import '../../data/services/time_table_pdf_service.dart';
import '../common/widgets/class_dropdown.dart';
import '../../core/utils/drive_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/bus_routine_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/bus_service.dart';
import '../../data/models/bus_destination.dart';

class RoutineManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<AuthService>(context).role;

    if (!['management', 'principal', 'admin'].contains(userRole)) {
       return Scaffold(
        appBar: AppBar(title: Text("Access Denied")),
        body: Center(child: Text("Only Management and Principal can edit routines.")),
      );
    }
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Routine Management'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Class Routine', icon: Icon(Icons.class_)),
              Tab(text: 'Bus Routine', icon: Icon(Icons.directions_bus)),
              Tab(text: 'Time Table', icon: Icon(Icons.table_chart)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RoutineList(type: 'class'),
            _BusRoutineTab(),
            _TimeTableTab(),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    // Existing logic moved to specific lists or kept as general
    // I'll keep it for 'class' and 'bus' inside the respective views or here.
  }
}

class _TimeTableTab extends StatefulWidget {
  @override
  __TimeTableTabState createState() => __TimeTableTabState();
}

class __TimeTableTabState extends State<_TimeTableTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _selectedClass;
  Map<String, dynamic>? _selectedRoutine;
  
  // Table Data State
  List<String> _columns = [];
  List<List<String>> _rows = [];

  void _showSetupDialog() {
    final _numController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Setup Time Table Columns'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _numController,
              decoration: InputDecoration(
                labelText: 'No. of Extra Columns',
                helperText: '"Time Duration" will be added automatically',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final numCols = int.tryParse(_numController.text) ?? 0;
              Navigator.pop(context, numCols);
            },
            child: Text('Next'),
          ),
        ],
      ),
    ).then((numCols) {
      if (numCols != null) {
        _showColumnNamesDialog(numCols);
      }
    });
  }

  void _showColumnNamesDialog(int numCols) {
    List<TextEditingController> controllers = List.generate(numCols, (_) => TextEditingController());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Column Names'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(numCols, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: controllers[index],
                decoration: InputDecoration(
                  labelText: 'Column ${index + 1}',
                  border: OutlineInputBorder(),
                ),
              ),
            )),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _columns = ["Time Duration"];
                _columns.addAll(controllers.map((c) => c.text.isEmpty ? "Subject ${controllers.indexOf(c) + 1}" : c.text));
                _rows = []; 
                _selectedRoutine = null;
              });
              Navigator.pop(context);
            },
            child: Text('Create Table'),
          )
        ],
      ),
    );
  }

  Future<void> _selectTimeRange(int rowIndex) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 8, minute: 0),
      helpText: "Select Start Time",
    );
    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
      helpText: "Select End Time",
    );
    if (endTime == null) return;

    setState(() {
      _rows[rowIndex][0] = "${startTime.format(context)} - ${endTime.format(context)}";
    });
  }

  void _printTable() {
    if (_columns.isEmpty) return;
    final config = Provider.of<SchoolConfigService>(context, listen: false);
    TimeTablePdfService.generate(
      schoolName: config.schoolName,
      address: "Main Campus, City Square, State - 123456", // Placeholder or fetch if possible
      columns: _columns,
      rows: _rows,
    );
  }

  Future<void> _saveTable() async {
    if (_columns.isEmpty) return;
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 15),
            Text('Saving Schedule...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final routineService = Provider.of<RoutineService>(context, listen: false);
      
      // Extremely safe data preparation for Firestore Web compatibility
      final List<dynamic> cleanColumns = _columns.map((e) => e.toString()).toList();
      
      // RESTRICTION FIX: Firestore does not support nested arrays.
      // We convert each row (List) into a Map (e.g., {"0": "time", "1": "subject"})
      final List<Map<String, dynamic>> cleanRows = _rows.map((row) {
        final Map<String, dynamic> rowMap = {};
        for (int i = 0; i < row.length; i++) {
          rowMap[i.toString()] = row[i].toString();
        }
        return rowMap;
      }).toList();

      final Map<String, dynamic> tableData = {
        'columns': cleanColumns,
        'rows': cleanRows,
      };
      
      if (_selectedRoutine != null) {
        // Safe access and conversion of existing routine data
        final String docId = _selectedRoutine!['id']?.toString() ?? "";
        final String title = (_selectedRoutine!['title'] ?? "School Time Table").toString();
        final String description = (_selectedRoutine!['description'] ?? "Structured time table").toString();
        final String? imageUrl = _selectedRoutine!['imageUrl']?.toString();

        await routineService.updateRoutine(
          docId, 
          title, 
          description, 
          imageUrl: imageUrl,
          tableData: tableData
        );
      } else {
        await routineService.addRoutine(
          "School Time Table", 
          "Structured time table for the entire school", 
          "timetable", 
          tableData: tableData
        );
        
        // Clear state to return to list view
        setState(() {
          _columns = [];
          _rows = [];
          _selectedRoutine = null;
        });
      }
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Time Table Saved Successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Color(0xFFF1F5F9), // Slate 100/dashboard background
      child: Column(
        children: [
          // Header Section - Premium Glassmorphism style
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4F46E5).withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _showSetupDialog,
                      icon: Icon(Icons.table_chart_outlined, size: 20),
                      label: Text('Create New Schedule', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_columns.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printTable,
                      icon: Icon(Icons.print_outlined, size: 20),
                      label: Text('Print Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF4F46E5),
                        side: BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (_columns.isNotEmpty) ...[
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          color: Color(0xFFF8FAFC),
                          child: Text(
                            "Schedule Editor",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40),
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Color(0xFFEEF2FF)),
                              dataRowHeight: 65,
                              headingRowHeight: 50,
                              columnSpacing: 24,
                              horizontalMargin: 20,
                              border: TableBorder(
                                horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.1)),
                              ),
                              columns: _columns.map((c) => DataColumn(
                                label: Expanded(child: Text(c.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1, color: Color(0xFF3730A3))))
                              )).toList(),
                              rows: _rows.asMap().entries.map((entry) {
                                int rowIndex = entry.key;
                                List<String> rowData = entry.value;
                                return DataRow(
                                  cells: rowData.asMap().entries.map((cellEntry) {
                                    int colIndex = cellEntry.key;
                                    if (colIndex == 0) {
                                      // Time Duration Cell - Modern Pill Style
                                      return DataCell(
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: InkWell(
                                            onTap: () => _selectTimeRange(rowIndex),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: cellEntry.value.isEmpty ? Colors.grey[50] : Color(0xFFEEF2FF),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: cellEntry.value.isEmpty ? Colors.grey[200]! : Color(0xFFC7D2FE)),
                                              ),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.access_time, size: 14, color: cellEntry.value.isEmpty ? Colors.grey : Color(0xFF4F46E5)),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    cellEntry.value.isEmpty ? "Select" : cellEntry.value,
                                                    style: TextStyle(
                                                      color: cellEntry.value.isEmpty ? Colors.grey : Color(0xFF3730A3), 
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return DataCell(
                                      TextFormField(
                                        initialValue: cellEntry.value,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        decoration: InputDecoration(
                                          hintText: "Enter details...",
                                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                          border: InputBorder.none, 
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                        textAlign: TextAlign.center,
                                        onChanged: (val) => _rows[rowIndex][colIndex] = val,
                                      ),
                                    );
                                  }).toList(),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Floating-style Bottom Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _rows.add(List.generate(_columns.length, (_) => ""))),
                      icon: Icon(Icons.add_circle_outline, size: 20),
                      label: Text('Add Row', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF64748B), // Slate 500
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)], // Emerald 600-500
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981).withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveTable,
                        icon: Icon(Icons.check_circle_outline, size: 20),
                        label: Text('Save Schedule', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
          else
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Provider.of<RoutineService>(context).getRoutines('timetable'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                  final routines = snapshot.data ?? [];
                  if (routines.isEmpty) return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calendar_today_outlined, size: 48, color: Colors.indigo[300]),
                        ),
                        const SizedBox(height: 20),
                        Text('No schedules found', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Click the button above to create one.', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    )
                  );
                  
                  return ListView.builder(
                    padding: EdgeInsets.all(20),
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final r = routines[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.auto_awesome_motion_outlined, color: Color(0xFF4F46E5), size: 24),
                          ),
                          title: Text(r['title'] ?? 'School Time Table', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Click to manage structured schedule', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                              onPressed: () => Provider.of<RoutineService>(context, listen: false).deleteRoutine(r['id']),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedRoutine = r;
                              if (r['tableData'] != null) {
                                _columns = List<String>.from(r['tableData']['columns'] ?? []);
                                
                                // Handle both new Map format and old List format for backward compatibility
                                final rawRows = r['tableData']['rows'] as List? ?? [];
                                _rows = rawRows.map((row) {
                                  if (row is Map) {
                                    // New Map-based format: convert Map back to List
                                    final List<String> cells = List.generate(_columns.length, (_) => "");
                                    row.forEach((key, value) {
                                      final int? index = int.tryParse(key.toString());
                                      if (index != null && index < cells.length) {
                                        cells[index] = value.toString();
                                      }
                                    });
                                    return cells;
                                  } else {
                                    // Old List-based format
                                    return List<String>.from(row as List);
                                  }
                                }).toList();
                              }
                            });
                          },
                        ),
                      );
                    },
                  );
                }
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  final String type;

  const _RoutineList({required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<RoutineService>(context).getRoutines(type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No routines found.'));

          final routines = snapshot.data!;
          return Column(
            children: [
              if (type == 'class' && routines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final config = Provider.of<SchoolConfigService>(context, listen: false);
                      TimeTablePdfService.generateBulk(
                        schoolName: config.schoolName,
                        address: "Main Campus, City Square, State - 123456",
                        routines: routines,
                      );
                    },
                    icon: Icon(Icons.print_outlined),
                    label: Text('Print All Class Routines'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: Colors.indigo.withOpacity(0.4),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
              final routine = routines[index];
              final bool hasTable = routine['tableData'] != null;
              
              return Container(
                margin: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8)),
                  ],
                  border: Border.all(color: Colors.indigo.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.indigo[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.class_outlined, color: Colors.indigo[600], size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((routine['title'] ?? '').replaceAll('Routine - ', 'Class '), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                                Text(routine['description'] ?? '', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_note, color: Colors.indigo[400]),
                            onPressed: () => _showTableEditorDialog(context, routine),
                            tooltip: 'Edit Table Data',
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                            onPressed: () => Provider.of<RoutineService>(context, listen: false).deleteRoutine(routine['id']),
                            tooltip: 'Delete Routine',
                          ),
                        ],
                      ),
                    ),
                    if (hasTable)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5)),
                            ],
                            border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(Colors.indigo.shade900),
                                dataRowMinHeight: 48,
                                dataRowMaxHeight: 60,
                                horizontalMargin: 20,
                                columnSpacing: 24,
                                border: TableBorder.all(color: Colors.indigo.withOpacity(0.1), width: 1),
                                columns: List<String>.from(routine['tableData']['columns'] ?? [])
                                    .map((c) => DataColumn(
                                          label: Text(c, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
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
                                        color: MaterialStateProperty.resolveWith((states) {
                                          final day = cells[0].toString().toLowerCase();
                                          return day == 'sunday' ? Colors.red.shade50 : null;
                                        }),
                                        cells: cells.asMap().entries.map((cellEntry) {
                                          final isHeader = cellEntry.key == 0;
                                          final value = cellEntry.value.toString();
                                          return DataCell(
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              child: Text(
                                                value == "N/A" ? "-" : value,
                                                style: TextStyle(
                                                  fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                                                  color: isHeader ? Colors.indigo.shade900 : (value == "N/A" ? Colors.grey : Color(0xFF1E293B)),
                                                  fontSize: 13,
                                                ),
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
                      )
                    else if (routine['imageUrl'] != null && routine['imageUrl'] != "")
                       Padding(
                         padding: const EdgeInsets.all(20.0),
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(12),
                           child: Image.network(routine['imageUrl'], fit: BoxFit.cover, height: 200, width: double.infinity),
                         ),
                       ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  },
),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (type == 'class') {
            _showClassRoutineSetupDialog(context);
          } else {
            _showAddDialog(context);
          }
        },
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_task_rounded),
        label: Text("Create Routine"),
      ),
    );
  }

  void _showClassRoutineSetupDialog(BuildContext context) {
    int? _periodCount;
    List<TextEditingController> _timingControllers = [];
    String _holiday = "Sunday";
    bool _isHalfDay = false;
    String _halfDayName = "Saturday";
    int _halfDayPeriodCount = 4;
    bool _isGenerating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Class Routine Setup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'No. of school Period',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final count = int.tryParse(val);
                    if (count != null && count > 0) {
                      setState(() {
                        _periodCount = count;
                        _timingControllers = List.generate(count, (_) => TextEditingController());
                      });
                    }
                  },
                ),
                if (_periodCount != null) ...[
                  const SizedBox(height: 16),
                  Text('Set Period Timings', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(_periodCount!, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () async {
                        final TimeOfDay? startTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: 8 + index, minute: 0),
                          helpText: "Select Start Time for Period ${index + 1}",
                        );
                        if (startTime == null) return;

                        final TimeOfDay? endTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
                          helpText: "Select End Time for Period ${index + 1}",
                        );
                        if (endTime == null) return;

                        setState(() {
                          _timingControllers[index].text = "${startTime.format(context)} - ${endTime.format(context)}";
                        });
                      },
                      child: IgnorePointer(
                        child: TextField(
                          controller: _timingControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Period ${index + 1} Duration',
                            hintText: 'Tap to select time',
                            suffixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _holiday,
                  decoration: InputDecoration(labelText: 'Select Weekly Holiday', border: OutlineInputBorder()),
                  items: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                      .map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                  onChanged: (val) => setState(() => _holiday = val!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Half Day Configuration'),
                  value: _isHalfDay,
                  onChanged: (val) => setState(() => _isHalfDay = val),
                ),
                if (_isHalfDay) ...[
                  DropdownButtonFormField<String>(
                    value: _halfDayName,
                    decoration: InputDecoration(labelText: 'Select Half Day', border: OutlineInputBorder()),
                    items: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                        .map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (val) => setState(() => _halfDayName = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(labelText: 'No. of periods for half-day', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() => _halfDayPeriodCount = int.tryParse(val) ?? 4),
                  ),
                ],
                if (_isGenerating) 
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: _isGenerating || _periodCount == null ? null : () async {
                setState(() => _isGenerating = true);
                try {
                  final classService = Provider.of<ClassService>(context, listen: false);
                  final routineService = Provider.of<RoutineService>(context, listen: false);
                  
                  // 1. Delete existing class routines to prevent duplicates
                  final existingRoutinesSnapshot = await FirebaseFirestore.instance
                      .collection('routines')
                      .where('type', isEqualTo: 'class')
                      .get();
                  
                  for (var doc in existingRoutinesSnapshot.docs) {
                    await routineService.deleteRoutine(doc.id);
                  }

                  // 2. Fetch classes
                  final classes = await classService.fetchAllClasses();
                  
                  // 3. Prepare columns
                  final List<String> columns = ["DAYS"];
                  for (int i = 0; i < _periodCount!; i++) {
                    final timing = _timingControllers[i].text.trim();
                    columns.add("${i + 1}${_getOrdinalSuffix(i + 1)} Period${timing.isNotEmpty ? ' ($timing)' : ''}");
                  }

                  final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
                  
                  for (final cls in classes) {
                    final String title = "Class ${cls.name}";
                    final String desc = "Weekly structured routine for ${cls.name}";
                    
                    final List<Map<String, dynamic>> rows = [];
                    for (final day in days) {
                      if (day == _holiday) continue;
                      
                      final Map<String, dynamic> rowMap = {};
                      rowMap["0"] = day; // DAYS column
                      
                      int periodsForToday = _periodCount!;
                      if (_isHalfDay && day == _halfDayName) {
                        periodsForToday = _halfDayPeriodCount;
                      }
                      
                      for (int i = 0; i < _periodCount!; i++) {
                        if (i < periodsForToday) {
                          rowMap[(i + 1).toString()] = ""; // Empty cell for the period
                        } else {
                          rowMap[(i + 1).toString()] = "N/A"; // Marked as not available for half day
                        }
                      }
                      rows.add(rowMap);
                    }

                    await routineService.addRoutine(title, desc, 'class', tableData: {
                      'columns': columns,
                      'rows': rows,
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Routines generated for ${classes.length} classes')));
                } catch (e) {
                  setState(() => _isGenerating = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: Text('Submit & Generate'),
            ),
          ],
        ),
      ),
    );
  }

  String _getOrdinalSuffix(int i) {
    if (i >= 11 && i <= 13) return 'th';
    switch (i % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
  void _showAddDialog(BuildContext context) {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    final _imageController = TextEditingController();
    String _selectedType = type;
    String? _selectedClass; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Routine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == 'class')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ClassDropdown(
                    value: _selectedClass,
                    labelText: "Select Class",
                    onChanged: (val) => setState(() => _selectedClass = val),
                  ),
                )
              else
                TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Routine Title')),
              
              TextField(controller: _descController, decoration: InputDecoration(labelText: 'Routine Details'), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: _imageController, decoration: InputDecoration(labelText: 'Image URL (Google Drive)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                String title = "";
                if (type == 'class') {
                  if (_selectedClass == null) return; 
                  title = "Class $_selectedClass";
                } else {
                  title = _titleController.text;
                }

                if (title.isNotEmpty && _descController.text.isNotEmpty) {
                  final String? directUrl = DriveHelper.getDirectDriveUrl(_imageController.text);
                  Provider.of<RoutineService>(context, listen: false)
                      .addRoutine(title, _descController.text, type, imageUrl: directUrl);
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> routine) {
    final _titleController = TextEditingController(text: routine['title']);
    final _descController = TextEditingController(text: routine['description']);
    final _imageController = TextEditingController(text: routine['imageUrl']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Routine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: _descController, decoration: InputDecoration(labelText: 'Routine Details'), maxLines: 5),
            const SizedBox(height: 8),
            TextField(controller: _imageController, decoration: InputDecoration(labelText: 'Image URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
           onPressed: () {
               final String? directUrl = DriveHelper.getDirectDriveUrl(_imageController.text);
               Provider.of<RoutineService>(context, listen: false)
                  .updateRoutine(routine['id'], _titleController.text, _descController.text, imageUrl: directUrl);
               Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
  void _showTableEditorDialog(BuildContext context, Map<String, dynamic> routine) {
    if (routine['tableData'] == null) return;
    
    final List<String> columns = List<String>.from(routine['tableData']['columns'] ?? []);
    final rawRows = routine['tableData']['rows'] as List? ?? [];
    
    // De-serialize rows
    final List<List<String>> tempRows = rawRows.map((row) {
      if (row is Map) {
        final List<String> cells = List.generate(columns.length, (_) => "");
        row.forEach((key, value) {
          final int? index = int.tryParse(key.toString());
          if (index != null && index < cells.length) {
            cells[index] = value.toString();
          }
        });
        return cells;
      } else {
        return List<String>.from(row as List);
      }
    }).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Routine Table: ${routine['title']}'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: columns.map((c) => DataColumn(label: Text(c, style: TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  rows: tempRows.asMap().entries.map((rowEntry) {
                    final int rowIndex = rowEntry.key;
                    final List<String> row = rowEntry.value;
                    
                    return DataRow(
                      cells: row.asMap().entries.map((cellEntry) {
                        final int colIndex = cellEntry.key;
                        final String cellValue = cellEntry.value;
                        
                        return DataCell(
                          colIndex == 0 
                            ? Text(cellValue, style: TextStyle(fontWeight: FontWeight.bold))
                            : TextField(
                                controller: TextEditingController(text: cellValue)..selection = TextSelection.collapsed(offset: cellValue.length),
                                decoration: InputDecoration(border: InputBorder.none),
                                onChanged: (val) => tempRows[rowIndex][colIndex] = val,
                              ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                // Convert to persistent Map format
                final List<Map<String, dynamic>> cleanRows = tempRows.map((row) {
                  final Map<String, dynamic> rowMap = {};
                  for (int i = 0; i < row.length; i++) {
                    rowMap[i.toString()] = row[i];
                  }
                  return rowMap;
                }).toList();

                await Provider.of<RoutineService>(context, listen: false).updateRoutine(
                  routine['id'],
                  routine['title'] ?? "",
                  routine['description'] ?? "",
                  tableData: {
                    'columns': columns,
                    'rows': cleanRows,
                  },
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Routine table updated!')));
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusRoutineTab extends StatefulWidget {
  @override
  _BusRoutineTabState createState() => _BusRoutineTabState();
}

class _BusRoutineTabState extends State<_BusRoutineTab> {
  String? _selectedDriverId;
  int _selectedTrip = 1;
  String _selectedType = 'Arrival';
  List<BusRoutineStop> _currentStops = [];
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          _buildPremiumSelectors(),
          Expanded(
            child: _selectedDriverId == null 
              ? _buildEmptyState("Select a driver to begin", Icons.person_search_rounded)
              : _buildPremiumRoutineEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSelectors() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Routine Configuration", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade900, fontSize: 16)),
          SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Provider.of<UserService>(context).getStaffMembers(),
            builder: (context, snapshot) {
              final drivers = (snapshot.data ?? []).where((u) => u['role'] == 'driver').toList();
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDriverId,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.person_pin, color: Colors.indigo),
                      labelText: "Select Bus Driver",
                    ),
                    items: drivers.map((d) => DropdownMenuItem(
                      value: d['id'] as String,
                      child: Text(d['name'] ?? 'Unknown Driver', style: TextStyle(fontWeight: FontWeight.w500)),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDriverId = val;
                        _loadRoutine();
                      });
                    },
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Trip Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(5, (index) {
                          final tripNum = index + 1;
                          final isSelected = _selectedTrip == tripNum;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text("T$tripNum"),
                              onSelected: (val) {
                                setState(() {
                                  _selectedTrip = tripNum;
                                  _loadRoutine();
                                });
                              },
                              selectedColor: Colors.indigo.shade100,
                              checkmarkColor: Colors.indigo,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.indigo.shade900 : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Direction", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  SizedBox(height: 8),
                  ToggleButtons(
                    children: [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Arrival")),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Departure")),
                    ],
                    isSelected: [_selectedType == 'Arrival', _selectedType == 'Departure'],
                    onPressed: (index) {
                      setState(() {
                        _selectedType = index == 0 ? 'Arrival' : 'Departure';
                        _loadRoutine();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: Colors.indigo,
                    color: Colors.indigo.shade900,
                    constraints: BoxConstraints(minHeight: 40),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _loadRoutine() {
    if (_selectedDriverId == null) return;
    final service = Provider.of<BusRoutineService>(context, listen: false);
    service.getRoutine(_selectedDriverId!, _selectedTrip, _selectedType).first.then((routine) {
      if (mounted) {
        setState(() {
          _currentStops = routine?.stops ?? [];
        });
      }
    });
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.indigo.shade200),
          ),
          SizedBox(height: 24),
          Text(msg, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPremiumRoutineEditor() {
    return Column(
      children: [
        Expanded(
          child: _currentStops.isEmpty 
            ? _buildEmptyState("No stops yet. Add your first stop.", Icons.add_location_alt_rounded)
            : ReorderableListView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _currentStops.removeAt(oldIndex);
                    _currentStops.insert(newIndex, item);
                  });
                },
                children: [
                  for (int i = 0; i < _currentStops.length; i++)
                    _buildPremiumStopTile(i, _currentStops[i]),
                ],
              ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildPremiumStopTile(int index, BusRoutineStop stop) {
    return Container(
      key: ValueKey(stop.stopId + index.toString()),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo, Colors.blue]),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text("${index + 1}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        title: Text(stop.stopName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Row(
          children: [
            Icon(Icons.access_time_filled, size: 14, color: Colors.indigo.shade300),
            SizedBox(width: 4),
            Text(stop.time, style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconButton(Icons.edit_calendar_rounded, Colors.blue, () => _editStopTime(index)),
            SizedBox(width: 8),
            _buildIconButton(Icons.delete_sweep_rounded, Colors.red, () => setState(() => _currentStops.removeAt(index))),
            SizedBox(width: 12),
            Icon(Icons.drag_indicator_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showAddStopDialog,
              icon: Icon(Icons.add_location_alt_rounded),
              label: Text("Add Stop"),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: Colors.indigo),
                foregroundColor: Colors.indigo,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveRoutine,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade900,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.indigo.withOpacity(0.4),
              ),
              child: _isSaving 
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStopDialog() {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<BusDestination>>(
        stream: Provider.of<BusService>(context).getDestinations(),
        builder: (context, snapshot) {
          final destinations = snapshot.data ?? [];
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text("Choose Bus Stop", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: destinations.isEmpty 
                ? _buildEmptyState("No stops found", Icons.location_off_rounded)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final dest = destinations[index];
                      return ListTile(
                        leading: Icon(Icons.location_on, color: Colors.indigo),
                        title: Text(dest.name, style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text("₹${dest.fee}"),
                        onTap: () => _addStopToRoutine(dest),
                      );
                    },
                  ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
          );
        },
      ),
    );
  }

  void _addStopToRoutine(BusDestination dest) async {
    Navigator.pop(context);
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.indigo),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _currentStops.add(BusRoutineStop(
        stopId: dest.id,
        stopName: dest.name,
        time: time.format(context),
      ));
    });
  }

  void _editStopTime(int index) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.indigo),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _currentStops[index] = BusRoutineStop(
        stopId: _currentStops[index].stopId,
        stopName: _currentStops[index].stopName,
        time: time.format(context),
      );
    });
  }

  Future<void> _saveRoutine() async {
    setState(() => _isSaving = true);
    try {
      await Provider.of<BusRoutineService>(context, listen: false)
          .saveRoutine(_selectedDriverId!, _selectedTrip, _selectedType, _currentStops);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✨ Routine Updated Successfully!"),
          backgroundColor: Colors.indigo,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

