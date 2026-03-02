import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/user_service.dart';
import '../../data/services/class_service.dart';
import '../../data/models/class_model.dart';

class ClassStudentsScreen extends StatefulWidget {
  final ClassModel assignedClass;

  const ClassStudentsScreen({required this.assignedClass});

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final classService = Provider.of<ClassService>(context);

    // Filter students by classId
    return StreamBuilder<List<ClassModel>>(
      stream: classService.getAllClasses(),
      builder: (context, classSnapshot) {
        final currentClass = classSnapshot.data?.firstWhere(
          (c) => c.id == widget.assignedClass.id,
          orElse: () => widget.assignedClass,
        ) ?? widget.assignedClass;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.indigo[900],
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Excel View: Class ${currentClass.name}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _showAddColumnDialog(context, classService, currentClass.id),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                label: Text('Add Column', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: userService.getStudentsByClass(currentClass.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                    }
                    
                    final filteredStudents = snapshot.data ?? [];

                    if (filteredStudents.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No students found', 
                              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                            child: DataTable(
                            headingRowHeight: 40,
                            dataRowHeight: 45,
                            columnSpacing: 20,
                            border: TableBorder.all(color: Colors.grey[200]!),
                            headingTextStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            dataTextStyle: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                            headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                            columns: [
                              const DataColumn(label: Text('Adm.no')),
                              const DataColumn(label: Text('Roll.no')),
                              const DataColumn(label: Text('Student Name')),
                              const DataColumn(label: Text('Father Name')),
                              const DataColumn(label: Text('Sec')),
                              ...currentClass.customColumns.map((col) => DataColumn(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(col),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => classService.removeCustomColumn(currentClass.id, col),
                                      child: const Icon(Icons.close, size: 14, color: Colors.red),
                                    ),
                                  ],
                                ),
                              )),
                              const DataColumn(label: Text('Edit')),
                            ],
                            rows: filteredStudents.map((student) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(student['admNo'] ?? 'N/A')),
                                  DataCell(Text((student['customData'] as Map<String, dynamic>?)?['Roll.no']?.toString() ?? '-')),
                                  DataCell(Text(student['name'] ?? 'Unknown')),
                                  DataCell(Text(student['fatherName'] ?? 'N/A')),
                                  DataCell(Text((student['customData'] as Map<String, dynamic>?)?['Sec']?.toString() ?? '-')),
                                  ...currentClass.customColumns.map((col) {
                                    final dynamic val = (student['customData'] as Map<String, dynamic>?)?[col];
                                    return DataCell(Text(val?.toString() ?? '-'));
                                  }),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                      onPressed: () => _showEditDialog(context, userService, student, currentClass.customColumns),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showAddColumnDialog(BuildContext context, ClassService classService, String classId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Column', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Column Name (e.g. Marks, Remarks, etc.)',
            hintText: 'Enter column title',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                classService.addCustomColumn(classId, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context, 
    UserService userService, 
    Map<String, dynamic> student,
    List<String> customCols,
  ) {
    final controllers = <String, TextEditingController>{};
    
    // Standard permanent editable fields
    final permanentCols = ['Roll.no', 'Sec'];
    for (var col in permanentCols) {
      final dynamic val = (student['customData'] as Map<String, dynamic>?)?[col];
      controllers[col] = TextEditingController(text: val?.toString() ?? '');
    }

    // Custom dynamic fields
    for (var col in customCols) {
      final dynamic val = (student['customData'] as Map<String, dynamic>?)?[col];
      controllers[col] = TextEditingController(text: val?.toString() ?? '');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Data: ${student['name']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...permanentCols.map((col) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[col],
                  decoration: InputDecoration(
                    labelText: col,
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
              if (customCols.isNotEmpty) const Divider(),
              ...customCols.map((col) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[col],
                  decoration: InputDecoration(
                    labelText: col,
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> customData = Map<String, dynamic>.from(student['customData'] ?? {});
              
              // Save permanent fields
              for (var col in permanentCols) {
                customData[col] = controllers[col]!.text.trim();
              }
              
              // Save custom fields
              for (var col in customCols) {
                customData[col] = controllers[col]!.text.trim();
              }
              
              await userService.updateProfile(student['id'], {'customData': customData});
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    // This method is now replaced by _showEditDialog in the main table
  }
}
