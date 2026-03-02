
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/core/constants/app_constants.dart';
import 'package:vps/features/common/widgets/modern_layout.dart';
import '../../data/services/user_service.dart';
import '../common/widgets/class_dropdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/utils/migration_util.dart';
import '../../core/utils/drive_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserManagementScreen extends StatefulWidget {
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'User Management',
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            _buildActionHeader(context),
            _buildModernTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _UserList(roleFilter: 'pending', searchQuery: _searchQuery),
                  _UserList(roleFilter: 'student', searchQuery: _searchQuery),
                  _UserList(roleFilter: 'teacher', searchQuery: _searchQuery),
                  _UserList(roleFilter: 'staff', searchQuery: _searchQuery),
                  _UserList(roleFilter: 'passed_out', searchQuery: _searchQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.dashboardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or ID...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        padding: EdgeInsets.all(4),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        labelColor: AppColors.modernPrimary,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: [
          Tab(text: 'Pending'),
          Tab(text: 'Students'),
          Tab(text: 'Teachers'),
          Tab(text: 'Staff'),
          Tab(text: 'Passed Out'),
        ],
      ),
    );
  }

  Future<void> _showMigrationDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Sync Database'),
          ],
        ),
        content: Text('This will standardize class IDs and fix data inconsistencies. Run migration?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.modernPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Run Standardize'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Standardizing Data...')));
        await MigrationUtil.standardizeClassIds(); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Success! Classes are now consistent.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- Logic helpers copied from original with UI enhancements ---

  void _showApprovalDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Approve ${user['name']} as...'),
        children: [
          _RoleOption(label: 'Student', icon: Icons.school, color: Colors.purple, onTap: () {
            Navigator.pop(context);
            _showStudentClassDialog(context, user);
          }),
          _RoleOption(label: 'Teacher', icon: Icons.person_search, color: Colors.orange, onTap: () {
            Provider.of<UserService>(context, listen: false).updateUserRole(user['id'], 'teacher');
            Navigator.pop(context);
          }),
          _RoleOption(label: 'Staff', icon: Icons.badge, color: Colors.blue, onTap: () {
            Provider.of<UserService>(context, listen: false).updateUserRole(user['id'], 'staff');
            Navigator.pop(context);
          }),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Assign Class"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Assign ${user['name']} to a class:"),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Provider.of<UserService>(context, listen: false)
                    .updateUserRole(user['id'], 'student', classId: selectedClass);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.modernPrimary),
            child: Text("Finalize Approval"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> user) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete User?'),
        content: Text('Remove ${user['name']} from the system? This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
               Provider.of<UserService>(context, listen: false).deleteUser(user['id']);
               Navigator.pop(context);
            },
            child: Text('Confirm Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPhotoUpdateOptions(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.link, color: Colors.blue),
              ),
              title: Text('Paste Drive Link'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog(context, userId);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(context, userId);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context, String userId) {
    final _urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Profile Photo URL'),
        content: TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'Direct Drive Link',
            hintText: 'https://drive.google.com/...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final String? directUrl = DriveHelper.getDirectDriveUrl(_urlController.text);
              if (directUrl != null && directUrl.isNotEmpty) {
                Provider.of<UserService>(context, listen: false).updateProfile(userId, {'photoUrl': directUrl});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.modernPrimary),
            child: Text('Update'),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploading...')));
        await Provider.of<UserService>(context, listen: false).uploadProfilePhoto(userId, File(image.path));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Success!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  static Widget _buildSectionHeaderStatic(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.modernPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppColors.modernPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(indent: 16, color: Color(0xFFF0F0F0))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String roleFilter;
  final String searchQuery;

  const _UserList({required this.roleFilter, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context, listen: false).getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return _buildEmptyState('No users registered yet.');
        }

        final filteredUsers = data.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          final id = (u['admNo'] ?? u['teacherId'] ?? u['staffId'] ?? '').toString().toLowerCase();
          
          final matchesSearch = name.contains(searchQuery) || 
                               email.contains(searchQuery) || 
                               id.contains(searchQuery);
          
          if (!matchesSearch) return false;

          final r = u['role'];
          if (roleFilter == 'staff') {
             return r != 'student' && r != 'teacher' && r != 'principal' && r != 'pending' && r != 'passed_out' && r != 'admin';
          }
          return r == roleFilter;
        }).toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(searchQuery.isEmpty ? 'No $roleFilter found.' : 'No results for "$searchQuery"');
        }

        if (roleFilter == 'student' || roleFilter == 'passed_out') {
          return _buildGroupedList(filteredUsers);
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 180,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) => UserCard(user: filteredUsers[index], roleFilter: roleFilter),
        );
      },
    );
  }

  Widget _buildGroupedList(List<Map<String, dynamic>> users) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var user in users) {
      String key;
      if (roleFilter == 'student') {
        key = user['classId']?.toString() ?? 'Unassigned';
        if (key != 'Unassigned') key = 'Class $key';
      } else {
        key = user['passedOutSession']?.toString() ?? 'Unknown Session';
        if (key != 'Unknown Session') key = 'Session $key';
      }
      grouped.putIfAbsent(key, () => []).add(user);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      if (roleFilter == 'passed_out') return b.compareTo(a);
      return a.compareTo(b);
    });

    return CustomScrollView(
      slivers: [
        for (var key in sortedKeys) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverToBoxAdapter(
              child: _UserManagementScreenState._buildSectionHeaderStatic(key, grouped[key]!.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 180,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => UserCard(user: grouped[key]![index], roleFilter: roleFilter),
                childCount: grouped[key]!.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String roleFilter;

  const UserCard({Key? key, required this.user, required this.roleFilter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user['email'] ?? 'No email',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoBadge(),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Divider(height: 24, color: Colors.grey.shade50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPhoneAction(),
              Row(
                children: [
                  _CircleToolButton(
                    icon: Icons.add_a_photo,
                    color: Colors.blue,
                    onTap: () {
                      final state = context.findAncestorStateOfType<_UserManagementScreenState>();
                      if (state != null) state._showPhotoUpdateOptions(context, user['id']);
                    },
                    tooltip: 'Update Photo',
                  ),
                  const SizedBox(width: 8),
                  if (roleFilter == 'pending') ...[
                    _CircleToolButton(
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onTap: () {
                        final state = context.findAncestorStateOfType<_UserManagementScreenState>();
                        if (state != null) state._showApprovalDialog(context, user);
                      },
                      tooltip: 'Approve',
                    ),
                    const SizedBox(width: 8),
                    _CircleToolButton(
                      icon: Icons.cancel,
                      color: Colors.red,
                      onTap: () {
                        final state = context.findAncestorStateOfType<_UserManagementScreenState>();
                        if (state != null) state._confirmDelete(context, user);
                      },
                      tooltip: 'Reject',
                    ),
                  ] else
                    _CircleToolButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () {
                        final state = context.findAncestorStateOfType<_UserManagementScreenState>();
                        if (state != null) state._confirmDelete(context, user);
                      },
                      tooltip: 'Delete',
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    final photoUrl = DriveHelper.getDirectDriveUrl(user['photoUrl']?.toString() ?? '');
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.modernPrimary.withOpacity(0.2), width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.dashboardBackground,
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? Text(user['name']?[0] ?? 'U', style: TextStyle(color: AppColors.modernPrimary, fontWeight: FontWeight.bold)) 
            : null,
      ),
    );
  }

  Widget _buildInfoBadge() {
    String label = '';
    Color color = Colors.grey;

    if (roleFilter == 'student') {
      final admNo = user['admNo'] ?? 'N/A';
      label = 'ID: $admNo | Class: ${user['classId'] ?? "N/A"}';
      color = Colors.purple;
    } else {
      final id = user['teacherId'] ?? user['staffId'] ?? 'N/A';
      label = 'ID: $id | DOB: ${user['dob'] ?? user['age'] ?? "N/A"}';
      color = AppColors.modernPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPhoneAction() {
    final phone = user['phone'];
    return InkWell(
      onTap: phone != null ? () => launchUrl(Uri.parse('tel:$phone')) : null,
      child: Row(
        children: [
          Icon(Icons.phone_outlined, size: 14, color: phone != null ? Colors.blue : Colors.grey),
          const SizedBox(width: 4),
          Text(
            phone ?? 'No phone',
            style: TextStyle(
              fontSize: 12,
              color: phone != null ? Colors.blue : Colors.grey,
              decoration: phone != null ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleToolButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _CircleToolButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
