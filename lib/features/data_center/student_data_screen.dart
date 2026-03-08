import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/user_service.dart';

class StudentDataScreen extends StatefulWidget {
  @override
  _StudentDataScreenState createState() => _StudentDataScreenState();
}

class _StudentDataScreenState extends State<StudentDataScreen> {
  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Student Database', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userService.getAllStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No student data found.', style: TextStyle(color: Colors.grey)));
          }

          final students = snapshot.data!;

          return _ResponsiveDataView(
            students: students,
            onEditAdm: (s) => _editAdmNo(context, s),
          );
        },
      ),
    );
  }

  void _editAdmNo(BuildContext context, Map<String, dynamic> student) {
    final controller = TextEditingController(text: student['admNo'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Admission No.'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Admission Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newAdmNo = controller.text.trim();
              if (newAdmNo.isNotEmpty) {
                Provider.of<UserService>(context, listen: false)
                    .updateStudentAdmNo(student['id'], newAdmNo);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Admission No. updated for ${student['name']}'))
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

class _ResponsiveDataView extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final Function(Map<String, dynamic>) onEditAdm;

  const _ResponsiveDataView({required this.students, required this.onEditAdm});

  @override
  State<_ResponsiveDataView> createState() => _ResponsiveDataViewState();
}

class _ResponsiveDataViewState extends State<_ResponsiveDataView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Sort students numerically by admNo
    final sortedStudents = widget.students.toList();
    sortedStudents.sort((a, b) {
      final admA = a['admNo']?.toString() ?? '';
      final admB = b['admNo']?.toString() ?? '';
      
      // Extract numeric part using regex
      final numA = int.tryParse(RegExp(r'(\d+)').firstMatch(admA)?.group(1) ?? '') ?? 0;
      final numB = int.tryParse(RegExp(r'(\d+)').firstMatch(admB)?.group(1) ?? '') ?? 0;
      
      if (numA != numB) return numA.compareTo(numB);
      return admA.compareTo(admB); // Fallback to string compare
    });

    final filteredStudents = sortedStudents.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final adm = (s['admNo'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             adm.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildExcelView(filteredStudents);
              } else {
                return _buildListView(filteredStudents);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name or admission number...',
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

  Widget _buildExcelView(List<Map<String, dynamic>> students) {
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
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(label: Text('Adm No.', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Father Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Mother Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Date of Birth', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aadhar No', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Bank Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Account No', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('IFSC', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: students.map((student) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(student['admNo'] ?? 'N/A', 
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 14, color: Colors.blue),
                      ],
                    ),
                    onTap: () => widget.onEditAdm(student),
                  ),
                  DataCell(Text(student['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(student['fatherName'] ?? 'N/A')),
                  DataCell(Text(student['motherName'] ?? 'N/A')),
                  DataCell(Text(student['classId'] != null ? 'Class ${student['classId']}' : 'N/A')),
                  DataCell(Text(student['dob'] ?? student['age'] ?? 'N/A')),
                  DataCell(Text(student['gender'] ?? 'N/A')),
                  DataCell(Text(student['phone'] ?? 'N/A')),
                  DataCell(Text(student['address'] ?? 'N/A')),
                  DataCell(Text(student['aadharNo'] ?? 'N/A')),
                  DataCell(Text(student['bankName'] ?? 'N/A')),
                  DataCell(Text(student['bankAccountNo'] ?? 'N/A')),
                  DataCell(Text(student['ifscCode'] ?? 'N/A')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> students) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo[50],
              child: Text(student['name']?[0] ?? 'S', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
            ),
            title: Text(student['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${student['admNo'] ?? 'N/A'} • Class: ${student['classId'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow('Admission Number', student['admNo'] ?? 'N/A', isBlue: true, onEdit: () => widget.onEditAdm(student)),
                    _detailRow('Father Name', student['fatherName'] ?? 'N/A'),
                    _detailRow('Mother Name', student['motherName'] ?? 'N/A'),
                    _detailRow('Date of Birth', student['dob'] ?? student['age'] ?? 'N/A'),
                    _detailRow('Gender', student['gender'] ?? 'N/A'),
                    _detailRow('Phone', student['phone'] ?? 'N/A'),
                    _detailRow('Address', student['address'] ?? 'N/A'),
                    _detailRow('Aadhar No', student['aadharNo'] ?? 'N/A'),
                    _detailRow('Bank Name', student['bankName'] ?? 'N/A'),
                    _detailRow('Account No', student['bankAccountNo'] ?? 'N/A'),
                    _detailRow('IFSC', student['ifscCode'] ?? 'N/A'),
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
