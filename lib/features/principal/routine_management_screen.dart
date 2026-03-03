
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/routine_service.dart';
import '../../data/services/auth_service.dart';
import '../common/widgets/class_dropdown.dart';
import '../../core/utils/drive_helper.dart';

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
              Tab(text: 'Class List', icon: Icon(Icons.class_)),
              Tab(text: 'Bus Routes', icon: Icon(Icons.directions_bus)),
              Tab(text: 'Time Table', icon: Icon(Icons.table_chart)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RoutineList(type: 'class'),
            _RoutineList(type: 'bus'),
            _RoutineList(type: 'timetable'),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    final _imageController = TextEditingController();
    String _selectedType = 'class';
    String? _selectedClass; // For dropdown

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Routine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: _selectedType,
                items: [
                  DropdownMenuItem(value: 'class', child: Text('Class Routine')),
                  DropdownMenuItem(value: 'bus', child: Text('Bus Routine')),
                  DropdownMenuItem(value: 'timetable', child: Text('Time Table')),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              if (_selectedType == 'class' || _selectedType == 'timetable')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ClassDropdown(
                    value: _selectedClass,
                    labelText: "Select Class",
                    onChanged: (val) => setState(() => _selectedClass = val),
                  ),
                )
              else
                TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Routine Title (e.g. Route 1)')),
              
              TextField(controller: _descController, decoration: InputDecoration(labelText: 'Routine Details'), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: _imageController, decoration: InputDecoration(labelText: 'Image URL (Google Drive)', hintText: 'https://drive.google.com/...')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                String title = "";
                if (_selectedType == 'class' || _selectedType == 'timetable') {
                  if (_selectedClass == null) return; // Validate
                  title = "${_selectedType == 'class' ? 'Class' : 'Time Table'} $_selectedClass";
                } else {
                  title = _titleController.text;
                }

                if (title.isNotEmpty && _descController.text.isNotEmpty) {
                  final String? directUrl = DriveHelper.getDirectDriveUrl(_imageController.text);
                  Provider.of<RoutineService>(context, listen: false)
                      .addRoutine(title, _descController.text, _selectedType, imageUrl: directUrl);
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
}

class _RoutineList extends StatelessWidget {
  final String type;

  const _RoutineList({required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<RoutineService>(context).getRoutines(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No routines found.'));

        final routines = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];
            return Card(
              child: ListTile(
                title: Text(routine['title'] ?? ''),
                subtitle: Text(routine['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => Provider.of<RoutineService>(context, listen: false).deleteRoutine(routine['id']),
                ),
                onTap: () => _showEditDialog(context, routine),
              ),
            );
          },
        );
      },
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
            TextField(controller: _imageController, decoration: InputDecoration(labelText: 'Image URL (Google Drive)', hintText: 'https://drive.google.com/...')),
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
}
