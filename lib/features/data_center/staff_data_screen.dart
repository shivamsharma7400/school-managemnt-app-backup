import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/user_service.dart';

class StaffDataScreen extends StatefulWidget {
  @override
  _StaffDataScreenState createState() => _StaffDataScreenState();
}

class _StaffDataScreenState extends State<StaffDataScreen> {
  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Staff Database', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userService.getStaffMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No staff data found.', style: TextStyle(color: Colors.grey)));
          }

          final staffMembers = snapshot.data!;

          return _ResponsiveStaffView(
            staffMembers: staffMembers,
            onEditId: (s) => _editStaffId(context, s),
          );
        },
      ),
    );
  }

  void _editStaffId(BuildContext context, Map<String, dynamic> staff) {
    final controller = TextEditingController(text: staff['staffId'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Staff ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Staff ID',
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
                    .updateStaffId(staff['id'], newId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Staff ID updated for ${staff['name']}'))
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

class _ResponsiveStaffView extends StatefulWidget {
  final List<Map<String, dynamic>> staffMembers;
  final Function(Map<String, dynamic>) onEditId;

  const _ResponsiveStaffView({required this.staffMembers, required this.onEditId});

  @override
  State<_ResponsiveStaffView> createState() => _ResponsiveStaffViewState();
}

class _ResponsiveStaffViewState extends State<_ResponsiveStaffView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredStaff = widget.staffMembers.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final id = (s['staffId'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             id.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildExcelView(filteredStaff);
              } else {
                return _buildListView(filteredStaff);
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
          hintText: 'Search by name or staff ID...',
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

  Widget _buildExcelView(List<Map<String, dynamic>> staffMembers) {
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
              DataColumn(label: Text('Staff ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Work Field', style: TextStyle(fontWeight: FontWeight.bold))),
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
            rows: staffMembers.map((staff) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(staff['staffId'] ?? 'N/A', 
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 14, color: Colors.blue),
                      ],
                    ),
                    onTap: () => widget.onEditId(staff),
                  ),
                  DataCell(Text(staff['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(staff['workField'] ?? 'N/A')),
                  DataCell(Text(staff['role'] ?? 'Staff')),
                  DataCell(Text(staff['phone'] ?? 'N/A')),
                  DataCell(Text('₹${staff['monthlySalary'] ?? 0}')),
                  DataCell(Text(staff['address'] ?? 'N/A')),
                  DataCell(Text(staff['aadharNo'] ?? 'N/A')),
                  DataCell(Text(staff['resumeLink'] ?? 'N/A', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
                  DataCell(Text(staff['bankName'] ?? 'N/A')),
                  DataCell(Text(staff['bankAccountNo'] ?? 'N/A')),
                  DataCell(Text(staff['ifscCode'] ?? 'N/A')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> staffMembers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staffMembers.length,
      itemBuilder: (context, index) {
        final staff = staffMembers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[50],
              child: Text(staff['name']?[0] ?? 'S', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            title: Text(staff['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${staff['staffId'] ?? 'N/A'} • ${staff['role'] ?? 'Staff'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow('Staff ID', staff['staffId'] ?? 'N/A', isBlue: true, onEdit: () => widget.onEditId(staff)),
                    _detailRow('Role', staff['role'] ?? 'Staff'),
                    _detailRow('Work Field', staff['workField'] ?? 'N/A'),
                    _detailRow('Salary', '₹${staff['monthlySalary'] ?? 0}'),
                    _detailRow('Phone', staff['phone'] ?? 'N/A'),
                    _detailRow('Address', staff['address'] ?? 'N/A'),
                    _detailRow('Aadhar No', staff['aadharNo'] ?? 'N/A'),
                    _detailRow('Resume', staff['resumeLink'] ?? 'N/A', isBlue: true),
                    _detailRow('Bank Name', staff['bankName'] ?? 'N/A'),
                    _detailRow('Account No', staff['bankAccountNo'] ?? 'N/A'),
                    _detailRow('IFSC', staff['ifscCode'] ?? 'N/A'),
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
