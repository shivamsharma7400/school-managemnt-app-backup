import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/class_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/class_model.dart';
import 'student_result_screen.dart';

class PrincipalResultViewScreen extends StatefulWidget {
  const PrincipalResultViewScreen({super.key});

  @override
  _PrincipalResultViewScreenState createState() => _PrincipalResultViewScreenState();
}

class _PrincipalResultViewScreenState extends State<PrincipalResultViewScreen> {
  String? _selectedClassId;
  String? _selectedClassName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Results')),
      body: Column(
        children: [
          _buildClassSelector(),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.indigo.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Class to View Results", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          StreamBuilder<List<ClassModel>>(
            stream: Provider.of<ClassService>(context).getAllClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return LinearProgressIndicator();
              if (!snapshot.hasData || snapshot.data!.isEmpty) return Text("No classes found");

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedClassId,
                    hint: Text("Choose a Class"),
                    items: snapshot.data!.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                        onTap: () {
                          setState(() {
                             _selectedClassName = c.name;
                          });
                        },
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedClassId = val),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_selectedClassId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Please select a class first", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context).getStudentsByClass(_selectedClassId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No students found in this class."));
        }

        final students = snapshot.data!;
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(student['name'][0].toUpperCase(), style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
                title: Text(student['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Roll No: ${student['rollNumber'] ?? 'N/A'}\nEmail: ${student['email']}"),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentResultScreen(
                    studentId: student['id'],
                    studentName: student['name'],
                    studentClass: _selectedClassName,
                    studentRoll: student['rollNumber'],
                  )));
                },
              ),
            );
          },
        );
      },
    );
  }
}
