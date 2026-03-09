import 'package:flutter/material.dart';
import 'student_data_screen.dart';
import 'teacher_data_screen.dart';
import 'staff_data_screen.dart';
import 'school_data_analysis_screen.dart';

class DataCenterScreen extends StatelessWidget {
  const DataCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Center'),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDataCard(
            context,
            'Student Data',
            Icons.school,
            Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDataScreen())),
          ),
          _buildDataCard(
            context,
            'Teacher Data',
            Icons.person,
            Colors.green,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherDataScreen())),
          ),
          _buildDataCard(
            context,
            'Staff Data',
            Icons.engineering,
            Colors.orange,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffDataScreen())),
          ),
          _buildDataCard(
            context,
            'School Data',
            Icons.analytics,
            Colors.purple,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => SchoolDataAnalysisScreen())),
          ),
          // More data-related cards can be added here
        ],
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
