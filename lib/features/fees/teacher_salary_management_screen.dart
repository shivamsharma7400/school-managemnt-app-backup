import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/user_service.dart';

class TeacherSalaryManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Salaries'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.calendar_month, size: 16),
              label: Text("Process Month"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmProcessMonth(context),
            ),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<UserService>(context).getTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No teachers found."));
          }

          final teachers = snapshot.data!;
          return ListView.builder(
            itemCount: teachers.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              return _TeacherSalaryCard(teacher: teachers[index]);
            },
          );
        },
      ),
    );
  }

  void _confirmProcessMonth(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Monthly Salary'),
        content: Text('This will add the monthly salary to the Total Due for ALL teachers. Do this only once a month.\n\nProceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Provider.of<UserService>(context, listen: false).processMonthlySalaryForAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salaries processed successfully')));
            },
            child: Text('Process'),
          ),
        ],
      ),
    );
  }
}

class _TeacherSalaryCard extends StatelessWidget {
  final Map<String, dynamic> teacher;

  const _TeacherSalaryCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final double salary = (teacher['monthlySalary'] as num?)?.toDouble() ?? 0.0;
    final double due = (teacher['salaryDue'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text((teacher['name'] ?? 'T')[0].toUpperCase())),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacher['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(teacher['email'] ?? '', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEditableField(context, "Monthly Salary", salary, (val) {
                  Provider.of<UserService>(context, listen: false).updateTeacherSalary(teacher['id'], val);
                }),
                _buildEditableField(context, "Total Due", due, (val) {
                  Provider.of<UserService>(context, listen: false).updateTeacherDue(teacher['id'], val);
                }, isRed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(BuildContext context, String label, double value, Function(double) onSave, {bool isRed = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
        Row(
          children: [
            Text(
              "₹ ${value.toStringAsFixed(0)}",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 18,
                color: isRed ? Colors.red : Colors.black
              )
            ),
            IconButton(
              icon: Icon(Icons.edit, size: 16, color: Colors.blue),
              onPressed: () => _showEditDialog(context, label, value, onSave),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            )
          ],
        )
      ],
    );
  }

  void _showEditDialog(BuildContext context, String label, double initialValue, Function(double) onSave) {
    final controller = TextEditingController(text: initialValue.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              onSave(val);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
