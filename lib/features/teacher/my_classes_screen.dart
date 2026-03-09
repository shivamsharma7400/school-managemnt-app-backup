import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/class_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/class_model.dart';
import '../common/widgets/class_dropdown.dart';

class MyClassesScreen extends StatelessWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacherId = Provider.of<AuthService>(context, listen: false).user?.uid;

    if (teacherId == null) return Scaffold(body: Center(child: Text("Error: No Teacher ID")));

    return Scaffold(
      appBar: AppBar(title: Text('My Classes')),
      body: StreamBuilder<List<ClassModel>>(
       // stream: Provider.of<ClassService>(context).getClassesForTeacher(teacherId), // If strictly filtering
        stream: Provider.of<ClassService>(context).getAllClasses(), // Assuming prototype shared view
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No classes assigned.'));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final classModel = snapshot.data![index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(classModel.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Teacher Assigned: ${classModel.teacherId == teacherId ? 'You' : 'Other'}"), // Simplification
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    // Navigate to class details or attendance history for this class
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Create Class (Demo)",
        onPressed: () {
          // Quick helper to create data for testing
          _showAddClassDialog(context, teacherId);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, String teacherId) {
    String? selectedClass;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Add New Class"),
          content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               ClassDropdown(
                 value: selectedClass,
                 onChanged: (val) => setState(() => selectedClass = val),
               ),
             ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedClass != null) {
                   // Prefixing with "Class " for display consistency if needed, 
                   // or just storing the number. User asked for standardized selection.
                   // I'll store "Class $selectedClass" to match previous convention or just "$selectedClass"
                   // Given previous code "Class 10-A", I will store "Class $selectedClass".
                   // Wait, strict list 1-8. I'll store "Class $selectedClass" for title.
                   await Provider.of<ClassService>(context, listen: false).createClass("Class $selectedClass", teacherId);
                   Navigator.pop(context);
                }
              }, 
              child: Text("Create")
            )
          ],
        ),
      ),
    );
  }
}
