import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/services/user_service.dart';
import '../../data/services/school_info_service.dart';

class StaffSalaryManagementScreen extends StatefulWidget {
  const StaffSalaryManagementScreen({super.key});

  @override
  _StaffSalaryManagementScreenState createState() => _StaffSalaryManagementScreenState();
}

class _StaffSalaryManagementScreenState extends State<StaffSalaryManagementScreen> {
  String _selectedSession = '2025-26'; // Default, will be updated from SchoolInfo

  @override
  void initState() {
    super.initState();
    _loadCurrentSession();
  }

  Future<void> _loadCurrentSession() async {
    try {
      final schoolService = Provider.of<SchoolInfoService>(context, listen: false);
      final data = await schoolService.getSchoolInfo();
      if (data != null && data['currentSession'] != null) {
        setState(() {
          _selectedSession = data['currentSession'];
        });
      }
    } catch (e) {
      print('Error loading session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Salaries'),
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
        stream: Provider.of<UserService>(context).getSalariedUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No staff found."));
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

  void _confirmProcessMonth(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    List<String> processedMonths = [];
    try {
      processedMonths = await userService.getProcessedMonths(_selectedSession);
    } catch (e) {
      print("Error fetching processed months: $e");
    }

    final months = [
      'April', 'May', 'June', 'July', 'August', 'September', 
      'October', 'November', 'December', 'January', 'February', 'March'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Process Monthly Salary'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("1. Session (Auto-selected)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                    ),
                    child: Text(
                      _selectedSession,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("2. Select Month to Process"),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: months.map((month) {
                      final isProcessed = processedMonths.contains(month);
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(month),
                            if (isProcessed) ...[
                              SizedBox(width: 4),
                              Icon(Icons.check_circle, size: 14, color: Colors.white)
                            ]
                          ],
                        ),
                        selected: isProcessed, // Visually selected if processed
                        selectedColor: Colors.green,
                        disabledColor: Colors.grey[200],
                        onSelected: isProcessed ? null : (selected) {
                           // Logic to select for processing
                           _executeProcessing(context, month, userService);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
            ],
          );
        }
      ),
    );
  }

  void _executeProcessing(BuildContext context, String month, UserService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $month"),
        content: Text("Process salaries for $month $_selectedSession?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm
              Navigator.pop(context); // Close main dialog
              try {
                await service.processMonthlySalary(_selectedSession, month);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processed $month $_selectedSession!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text("Confirm"),
          )
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
                Switch(
                  value: teacher['salaryEnabled'] ?? true, 
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    Provider.of<UserService>(context, listen: false).toggleSalaryStatus(teacher['id'], val);
                  }
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
            if (due > 0) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, teacher['id'], teacher['name'] ?? 'Staff', due),
                  icon: Icon(Icons.payment, size: 18),
                  label: Text("Record Payment (Pay)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String uid, String name, double due) {
    final controller = TextEditingController(text: due.toStringAsFixed(0));
    String method = "Cash";
    String month = DateFormat('MMMM').format(DateTime.now());
    
    final List<String> months = [
      "January", "February", "March", "April", "May", "June", 
      "July", "August", "September", "October", "November", "December"
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Pay Salary: $name'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Payment Amount",
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: month,
                    decoration: InputDecoration(
                      labelText: "Salary Month",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => month = val!),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: InputDecoration(
                      labelText: "Payment Method",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ["Cash", "Bank Transfer", "UPI", "Cheque"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => method = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text) ?? 0;
                  if (amount <= 0) return;
                  Navigator.pop(context);
                  try {
                    await Provider.of<UserService>(context, listen: false).recordStaffPayment(uid, amount, method, month);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment recorded for $name!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: Text('Confirm Payment'),
              ),
            ],
          );
        },
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
