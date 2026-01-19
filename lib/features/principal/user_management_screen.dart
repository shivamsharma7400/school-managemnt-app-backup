
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/user_service.dart';
import '../common/widgets/class_dropdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/utils/migration_util.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Provide UserService here or in main. Since it's specific, could be here, 
    // but better to have it global if we want it to stay alive. 
    // For now, I'll assume it's provided in main or I'll wrap it here locally if strictly needed.
    // I will add it to main.dart.
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('User Management'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Students'),
              Tab(text: 'Teachers'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.build),
              tooltip: 'Fix Database (Migrate Classes)',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Fix Database?'),
                    content: Text('This will standardize class IDs and fix "Unknown Class" issues. This is a one-time operation.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Run'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Migration Started...')));
                    // Import needed at top
                    await MigrationUtil.standardizeClassIds(); 
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Migration Complete!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _UserList(roleFilter: 'pending'),
            _UserList(roleFilter: 'student'),
            _UserList(roleFilter: 'teacher'),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String roleFilter;

  const _UserList({required this.roleFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context, listen: false).getAllUsers(), // Fetch all and filter client side for flexibility or create tailored streams
      // Actually filtering client side is easier for this scale.
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No users found.'));
        }

        final users = snapshot.data!.where((u) => u['role'] == roleFilter).toList();

        if (users.isEmpty) {
          return Center(child: Text('No $roleFilter users found.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
                  child: user['photoUrl'] == null ? Text(user['name']?[0] ?? 'U') : null,
                ),
                title: Text(user['name'] ?? 'Unknown Name', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (roleFilter == 'student') Text('Class: ${user['classId'] != null ? "Class ${user['classId']}" : "Unknown Class"}'),
                    Text(user['email'] ?? 'No Email'),
                    SizedBox(height: 4),
                    Row(
                      children: [
                         Icon(Icons.cake, size: 14, color: Colors.grey),
                         SizedBox(width: 4),
                         Text("Age: ${user['age'] ?? 'N/A'}"),
                         SizedBox(width: 16),
                         Icon(Icons.phone, size: 14, color: Colors.grey),
                         SizedBox(width: 4),
                         InkWell(
                           onTap: user['phone'] != null ? () => launchUrl(Uri.parse('tel:${user['phone']}')) : null,
                           child: Text(
                             "${user['phone'] ?? 'N/A'}", 
                             style: TextStyle(
                               color: user['phone'] != null ? Colors.blue : Colors.black,
                               decoration: user['phone'] != null ? TextDecoration.underline : null
                             )
                           ),
                         ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.blue),
                      tooltip: 'Upload Photo',
                      onPressed: () => _pickAndUploadPhoto(context, user['id']),
                    ),
                    if (roleFilter == 'pending') ...[
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () => _showApprovalDialog(context, user),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () => _confirmDelete(context, user),
                      ),
                    ] else
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, user),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showApprovalDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Approve ${user['name']} as...'),
        children: [
          SimpleDialogOption(
            child: Padding(padding: EdgeInsets.all(8), child: Text('Student', style: TextStyle(fontSize: 16))),
            onPressed: () {
              Navigator.pop(context);
              _showStudentClassDialog(context, user);
            },
          ),
          SimpleDialogOption(
            child: Padding(padding: EdgeInsets.all(8), child: Text('Teacher', style: TextStyle(fontSize: 16))),
            onPressed: () {
              // Teacher doesn't need class assignment on approval (usually assigned later)
              Provider.of<UserService>(context, listen: false).updateUserRole(user['id'], 'teacher');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showStudentClassDialog(BuildContext context, Map<String, dynamic> user) {
    String? selectedClass;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Assign Class to ${user['name']}"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select the class for this student. This determines fees."),
              SizedBox(height: 16),
              ClassDropdown(
                value: selectedClass,
                onChanged: (val) => selectedClass = val,
                validator: (val) => val == null ? 'Please select a class' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Provider.of<UserService>(context, listen: false)
                    .updateUserRole(user['id'], 'student', classId: selectedClass);
                Navigator.pop(context);
              }
            },
            child: Text("Approve"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> user) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User?'),
        content: Text('This will remove ${user['name']} from the database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
               Provider.of<UserService>(context, listen: false).deleteUser(user['id']);
               Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, String userId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploading photo...')));
        await Provider.of<UserService>(context, listen: false).uploadProfilePhoto(userId, File(image.path));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo uploaded successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
      }
    }
  }
}
