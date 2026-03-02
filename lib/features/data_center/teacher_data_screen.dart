import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/user_service.dart';
import '../../data/services/class_service.dart';
import '../../data/models/class_model.dart';

class TeacherDataScreen extends StatefulWidget {
  @override
  _TeacherDataScreenState createState() => _TeacherDataScreenState();
}

class _TeacherDataScreenState extends State<TeacherDataScreen> {
  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Teacher Database', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userService.getTeachers(),
        builder: (context, teacherSnapshot) {
          if (teacherSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!teacherSnapshot.hasData || teacherSnapshot.data!.isEmpty) {
            return const Center(child: Text('No teacher data found.', style: TextStyle(color: Colors.grey)));
          }

          final teachers = teacherSnapshot.data!;

          return _ResponsiveTeacherView(
            teachers: teachers,
            onEditId: (t) => _editTeacherId(context, t),
          );
        },
      ),
    );
  }

  void _editTeacherId(BuildContext context, Map<String, dynamic> teacher) {
    final controller = TextEditingController(text: teacher['teacherId'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Teacher ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Teacher ID',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newId = controller.text.trim();
              if (newId.isNotEmpty) {
                Provider.of<UserService>(context, listen: false)
                    .updateTeacherId(teacher['id'], newId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Teacher ID updated for ${teacher['name']}'))
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveTeacherView extends StatefulWidget {
  final List<Map<String, dynamic>> teachers;
  final Function(Map<String, dynamic>) onEditId;

  const _ResponsiveTeacherView({required this.teachers, required this.onEditId});

  @override
  State<_ResponsiveTeacherView> createState() => _ResponsiveTeacherViewState();
}

class _ResponsiveTeacherViewState extends State<_ResponsiveTeacherView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = widget.teachers.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final id = (t['teacherId'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             id.contains(_searchQuery.toLowerCase());
    }).toList();

    return StreamBuilder<List<ClassModel>>(
      stream: Provider.of<ClassService>(context).getAllClasses(),
      builder: (context, classSnapshot) {
        final classes = classSnapshot.data ?? [];
        
        return Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return _buildExcelView(filteredTeachers, classes);
                  } else {
                    return _buildListView(filteredTeachers, classes);
                  }
                },
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name or teacher ID...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      ),
    );
  }

  Widget _buildExcelView(List<Map<String, dynamic>> teachers, List<ClassModel> classes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(label: Text('Teacher ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Class Teacher', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Salary', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aadhar No', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Resume', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Bank Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Account No', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('IFSC', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: teachers.map((teacher) {
              final assignedClass = classes.firstWhere(
                (c) => c.teacherId == teacher['id'],
                orElse: () => ClassModel(id: '', name: 'None', teacherId: ''),
              );

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(teacher['teacherId'] ?? 'N/A', 
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 14, color: Colors.blue),
                      ],
                    ),
                    onTap: () => widget.onEditId(teacher),
                  ),
                  DataCell(Text(teacher['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(
                    DropdownButton<String>(
                      value: assignedClass.id.isEmpty ? null : assignedClass.id,
                      hint: const Text('Assign Class', style: TextStyle(fontSize: 12)),
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None', style: TextStyle(fontSize: 12))),
                        ...classes.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('Class ${c.name}', style: const TextStyle(fontSize: 12)),
                        )),
                      ],
                      onChanged: (newClassId) {
                        Provider.of<ClassService>(context, listen: false)
                            .assignClassTeacher(newClassId ?? '', teacher['id']);
                      },
                    ),
                  ),
                  DataCell(Text(teacher['teachingSubject'] ?? 'N/A')),
                  DataCell(Text(teacher['role'] ?? 'N/A')),
                  DataCell(Text(teacher['phone'] ?? 'N/A')),
                  DataCell(Text('₹${teacher['monthlySalary'] ?? 0}')),
                  DataCell(Text(teacher['address'] ?? 'N/A')),
                  DataCell(Text(teacher['aadharNo'] ?? 'N/A')),
                  DataCell(Text(teacher['resumeLink'] ?? 'N/A', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
                  DataCell(Text(teacher['bankName'] ?? 'N/A')),
                  DataCell(Text(teacher['bankAccountNo'] ?? 'N/A')),
                  DataCell(Text(teacher['ifscCode'] ?? 'N/A')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> teachers, List<ClassModel> classes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        final assignedClass = classes.firstWhere(
          (c) => c.teacherId == teacher['id'],
          orElse: () => ClassModel(id: '', name: '', teacherId: ''),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: Text(teacher['name']?[0] ?? 'T', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            title: Text(teacher['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              assignedClass.id.isNotEmpty ? 'Class Teacher: ${assignedClass.name}' : 'ID: ${teacher['teacherId'] ?? 'N/A'}',
              style: TextStyle(fontSize: 12, color: assignedClass.id.isNotEmpty ? Colors.indigo : Colors.grey[600]),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow('Assign Class', assignedClass.name.isEmpty ? 'None' : 'Class ${assignedClass.name}', 
                      isBlue: true,
                      onEdit: () {
                        // Show a simple class selector dialog for mobile
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Assign Class'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    title: const Text('None'),
                                    onTap: () {
                                      Provider.of<ClassService>(context, listen: false)
                                          .assignClassTeacher('', teacher['id']);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ...classes.map((c) => ListTile(
                                    title: Text('Class ${c.name}'),
                                    onTap: () {
                                      Provider.of<ClassService>(context, listen: false)
                                          .assignClassTeacher(c.id, teacher['id']);
                                      Navigator.pop(context);
                                    },
                                  )),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                    _detailRow('Teacher ID', teacher['teacherId'] ?? 'N/A', isBlue: true, onEdit: () => widget.onEditId(teacher)),
                    _detailRow('Role', teacher['role'] ?? 'N/A'),
                    _detailRow('Subject', teacher['teachingSubject'] ?? 'N/A'),
                    _detailRow('Salary', '₹${teacher['monthlySalary'] ?? 0}'),
                    _detailRow('Phone', teacher['phone'] ?? 'N/A'),
                    _detailRow('Address', teacher['address'] ?? 'N/A'),
                    _detailRow('Aadhar No', teacher['aadharNo'] ?? 'N/A'),
                    _detailRow('Resume', teacher['resumeLink'] ?? 'N/A', isBlue: true),
                    _detailRow('Bank Name', teacher['bankName'] ?? 'N/A'),
                    _detailRow('Account No', teacher['bankAccountNo'] ?? 'N/A'),
                    _detailRow('IFSC', teacher['ifscCode'] ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBlue = false, VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBlue ? Colors.blue : Colors.black87,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 16, color: Colors.blue),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
