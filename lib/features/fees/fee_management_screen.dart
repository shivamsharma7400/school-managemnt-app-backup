import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/services/class_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/fee_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/class_model.dart';
import '../../data/models/fee_record.dart'; // We use this for potentially paid tracking but mostly we compute live now

// Helper wrapper to avoid conflicting with services
// Assuming direct usage of SystemChrome for orientation
class SystemMirror {
    static void setPreferredOrientations(List<DeviceOrientation> orientations) {
      SystemChrome.setPreferredOrientations(orientations);
    }
}

class FeeManagementScreen extends StatefulWidget {
  @override
  _FeeManagementScreenState createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Force Landscape
    SystemMirror.setPreferredOrientations([
      DeviceOrientation.landscapeLeft, 
      DeviceOrientation.landscapeRight
    ]);
  }

  @override
  void dispose() {
    // Revert to Portrait
    SystemMirror.setPreferredOrientations([
      DeviceOrientation.portraitUp, 
      DeviceOrientation.portraitDown
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fee Management'),
        actions: [
          TextButton.icon(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
            label: Text(_isEditing ? 'Save' : 'Edit', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: Provider.of<ClassService>(context).getAllClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No classes found."));
          }

          final classes = snapshot.data!;
          // Sort classes by name if needed
          classes.sort((a, b) => a.name.compareTo(b.name));

          return ListView.builder(
            itemCount: classes.length,
            padding: EdgeInsets.all(8),
            itemBuilder: (context, index) {
              return ClassFeeCard(classModel: classes[index], isEditing: _isEditing);
            },
          );
        },
      ),
    );
  }
}

class ClassFeeCard extends StatelessWidget {
  final ClassModel classModel;
  final bool isEditing;

  const ClassFeeCard({Key? key, required this.classModel, required this.isEditing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                classModel.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Expanded(
              flex: 3,
              child: _FeeEditor(classModel: classModel, isEditing: isEditing),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             IconButton(
               icon: Icon(Icons.notifications_active, color: Colors.orange),
               tooltip: 'Notify Class',
               onPressed: () => _notifyClass(context, classModel),
             ),
             Icon(Icons.expand_more), 
          ],
        ),
        children: [
          _StudentList(classId: classModel.id, monthlyFee: classModel.monthlyFee),
        ],
      ),
    );
  }

  void _notifyClass(BuildContext context, ClassModel classModel) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notify Class ${classModel.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: bodyController, decoration: InputDecoration(labelText: 'Message'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                Provider.of<NotificationService>(context, listen: false)
                    .sendNotificationToClass(classModel.id, titleController.text, bodyController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notifications sending...')));
              }
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _FeeEditor extends StatefulWidget {
  final ClassModel classModel;
  final bool isEditing;
  const _FeeEditor({required this.classModel, required this.isEditing});

  @override
  __FeeEditorState createState() => __FeeEditorState();
}

class __FeeEditorState extends State<_FeeEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.classModel.monthlyFee.toStringAsFixed(0));
  }
  
  @override
  void didUpdateWidget(covariant _FeeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEditing && oldWidget.isEditing) {
       // Just switched from Edit to Read. Ensure controller matches model just in case.
       _controller.text = widget.classModel.monthlyFee.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("₹ ", style: TextStyle(fontWeight: FontWeight.bold)),
        if (widget.isEditing)
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true, 
                contentPadding: EdgeInsets.all(4),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                // Live save to ensure data isn't lost when toggling "Save"
                _saveFee(val);
              },
            ),
          )
        else
          Text(
            widget.classModel.monthlyFee.toStringAsFixed(0),
            style: TextStyle(fontSize: 16),
          ),
      ],
    );
  }

  void _saveFee(String val) {
    if (val.isEmpty) return;
    final fee = double.tryParse(val) ?? 0;
    // Debounce potential could be added here if needed, but for local firestore it's okay for now.
    Provider.of<ClassService>(context, listen: false).updateClassFee(widget.classModel.id, fee);
  }
}

class _StudentList extends StatelessWidget {
  final String classId;
  final double monthlyFee;

  const _StudentList({required this.classId, required this.monthlyFee});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context).getStudentsByClass(classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("No students in this class."),
          );
        }

        final students = snapshot.data!;
        
        return ListView.builder(
          shrinkWrap: true, // Vital for nesting in LV
          physics: NeverScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (context, index) {
            return _StudentFeeItem(student: students[index], baseFee: monthlyFee);
          },
        );
      },
    );
  }
}

class _StudentFeeItem extends StatelessWidget {
  final Map<String, dynamic> student;
  final double baseFee;

  const _StudentFeeItem({required this.student, required this.baseFee});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<FeeService>(context).getExtraCharges(student['id']),
      builder: (context, extraSnapshot) {
        double extraTotal = 0;
        List<Map<String, dynamic>> extras = [];
        if (extraSnapshot.hasData) {
          extras = extraSnapshot.data!;
          for (var e in extras) {
            extraTotal += (e['amount'] as num).toDouble();
          }
        }
        
        final totalFee = baseFee + extraTotal;
        final currentDue = (student['currentDue'] as num?)?.toDouble() ?? 0.0;

        return ListTile(
          leading: CircleAvatar(child: Text((student['name'] ?? 'U')[0].toUpperCase())),
          title: Row(
            children: [
              Expanded(child: Text(student['name'] ?? 'Unknown User')),
              InkWell(
                onTap: () => _editDueAmount(context, currentDue),
                child: Row(
                  children: [
                    Text(
                      "Due: ₹$currentDue", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.red
                      )
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly: ₹$baseFee + Extra: ₹$extraTotal'),
              if (extras.isNotEmpty)
                ...extras.map((e) => Text(
                  "${e['reason']}: ₹${e['amount']}",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                )).toList(),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.blue),
                tooltip: 'Add Extra Charge',
                onPressed: () => _addExtraCharge(context),
              ),
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                tooltip: 'Notify Student',
                onPressed: () => _notifyStudent(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editDueAmount(BuildContext context, double currentDue) {
    final controller = TextEditingController(text: currentDue.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Due Amount for ${student['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Total Current Due', prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
               final newDue = double.tryParse(controller.text) ?? 0;
               Provider.of<UserService>(context, listen: false).updateStudentDue(student['id'], newDue);
               Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _addExtraCharge(BuildContext context) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Extra Charge for ${student['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(controller: amountController, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
             TextField(controller: reasonController, decoration: InputDecoration(labelText: 'Reason (Required)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty && reasonController.text.isNotEmpty) {
                 final amount = double.tryParse(amountController.text) ?? 0;
                 if (amount > 0) {
                   Provider.of<FeeService>(context, listen: false)
                       .addExtraCharge(student['id'], amount, reasonController.text);
                   Navigator.pop(context);
                 }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _notifyStudent(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notify ${student['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: bodyController, decoration: InputDecoration(labelText: 'Message'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                Provider.of<NotificationService>(context, listen: false)
                    .sendNotificationToUser(student['id'], titleController.text, bodyController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification sent')));
              }
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }
}
