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
  const UserManagementScreen({super.key});

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
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<UserService>(context, listen: false).getAllUsers(),
        builder: (context, snapshot) {
          final users = snapshot.data ?? [];
          return DefaultTabController(
            length: 9, 
            child: Column(
              children: [
                _buildActionHeader(context),
                _buildModernTabBar(users),
                Expanded(
                  child: TabBarView(
                    children: [
                      _UserList(roleFilter: 'pending', requestedRoleFilter: 'student', searchQuery: _searchQuery, preFetchedUsers: users),
                      _UserList(roleFilter: 'pending', requestedRoleFilter: 'teacher', searchQuery: _searchQuery, preFetchedUsers: users),
                      _UserList(roleFilter: 'pending', requestedRoleFilter: 'staff', searchQuery: _searchQuery, preFetchedUsers: users),
                      _UserList(roleFilter: 'student', searchQuery: _searchQuery, preFetchedUsers: users),
                      _UserList(roleFilter: 'teacher', searchQuery: _searchQuery, preFetchedUsers: users),
                      _UserList(roleFilter: 'management', searchQuery: _searchQuery, preFetchedUsers: users),
                      _UserList(roleFilter: 'driver', searchQuery: _searchQuery, preFetchedUsers: users),
                      _UserList(roleFilter: 'staff', searchQuery: _searchQuery, preFetchedUsers: users),
                      _UserList(roleFilter: 'passed_out', searchQuery: _searchQuery, preFetchedUsers: users),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.sync_rounded, color: Colors.orange.shade700),
            onPressed: () => _showMigrationDialog(context),
            tooltip: 'Sync Database',
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar(List<Map<String, dynamic>> users) {
    int getCount(String role, {String? requestedRole}) {
      return users.where((u) {
        final r = u['role'];
        if (role == 'pending') {
          return r == 'pending' && (u['requestedRole'] ?? 'student') == requestedRole;
        }
        return r == role;
      }).length;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: TabBar(
        isScrollable: true,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        indicator: BoxDecoration(
          color: AppColors.modernPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.modernPrimary.withOpacity(0.2)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.modernPrimary,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: [
          _buildTab('Pending Students', Icons.school_outlined, getCount('pending', requestedRole: 'student'), Colors.orange),
          _buildTab('Pending Teachers', Icons.person_search_outlined, getCount('pending', requestedRole: 'teacher'), Colors.deepOrange),
          _buildTab('Pending Staff', Icons.badge_outlined, getCount('pending', requestedRole: 'staff'), Colors.brown),
          _buildTab('Students', Icons.groups_outlined, getCount('student'), Colors.blue),
          _buildTab('Teachers', Icons.record_voice_over_outlined, getCount('teacher'), Colors.green),
          _buildTab('Management', Icons.admin_panel_settings_outlined, getCount('management'), Colors.indigo),
          _buildTab('Drivers', Icons.directions_bus_outlined, getCount('driver'), Colors.cyan),
          _buildTab('Gen Staff', Icons.engineering_outlined, getCount('staff'), Colors.teal),
          _buildTab('Passed Out', Icons.history_edu_outlined, getCount('passed_out'), Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int count, Color color) {
    return Tab(
      height: 45,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 8),
          Text(label),
          if (count > 0) ...[
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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

  void _showApprovalDialog(BuildContext context, Map<String, dynamic> user) {
    final requestedRole = (user['requestedRole'] ?? 'student').toString().toLowerCase();

    if (requestedRole == 'student') {
      _showStudentClassDialog(context, user);
      return;
    }

    if (requestedRole == 'teacher') {
      Provider.of<UserService>(context, listen: false).updateUserRole(user['id'], 'teacher');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${user['name']} approved as Teacher'),
        backgroundColor: Colors.green,
      ));
      return;
    }

    // For Staff, show specific sub-roles
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Approve Staff as...'),
        children: [
          _RoleOption(
            label: 'Bus Driver', 
            icon: Icons.directions_bus, 
            color: Colors.blue, 
            onTap: () {
              Provider.of<UserService>(context, listen: false).updateUserRole(user['id'], 'driver');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved as Bus Driver')));
            }
          ),
          _RoleOption(
            label: 'Management Group', 
            icon: Icons.admin_panel_settings, 
            color: Colors.teal, 
            onTap: () {
              Provider.of<UserService>(context, listen: false).updateUserRole(user['id'], 'management');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved as Management Group')));
            }
          ),
          _RoleOption(
            label: 'General Staff', 
            icon: Icons.badge, 
            color: Colors.brown, 
            onTap: () {
              Provider.of<UserService>(context, listen: false).updateUserRole(user['id'], 'staff');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved as Staff')));
            }
          ),
        ],
      ),
    );
  }

  void _showStudentClassDialog(BuildContext context, Map<String, dynamic> user) {
    String? selectedClass;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Assign Class"),
        content: Form(
          key: formKey,
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
              if (formKey.currentState!.validate()) {
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
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Profile Photo URL'),
        content: TextField(
          controller: urlController,
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
              final String? directUrl = DriveHelper.getDirectDriveUrl(urlController.text);
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

  void _showPermissionsDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _PermissionsDialog(user: user),
    );
  }

  void _showPasswordDialog(BuildContext context, Map<String, dynamic> user) async {
    final userService = Provider.of<UserService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String?>(
        future: userService.getUserPassword(user['id']),
        builder: (context, snapshot) {
          final password = snapshot.data ?? 'Loading...';
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.key, color: Colors.orange),
                SizedBox(width: 12),
                Text('User Password'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${user['name']}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading 
                    ? Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(
                        children: [
                          Icon(Icons.lock_open, size: 16, color: Colors.grey),
                          SizedBox(width: 12),
                          Expanded(
                            child: SelectableText(
                              password,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                ),
                SizedBox(height: 12),
                Text(
                  'Please share this password with the user only after identity verification.',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          );
        },
      ),
    );
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
  final String? requestedRoleFilter;
  final String searchQuery;
  final List<Map<String, dynamic>> preFetchedUsers;

  const _UserList({
    required this.roleFilter, 
    this.requestedRoleFilter, 
    required this.searchQuery,
    required this.preFetchedUsers,
  });

  @override
  Widget build(BuildContext context) {
    final data = preFetchedUsers;
    if (data.isEmpty) {
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
          if (roleFilter == 'pending') {
            if (r != 'pending') return false;
            String reqRole = (u['requestedRole'] ?? 'student').toString().toLowerCase();
            return reqRole == requestedRoleFilter;
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
  }

  Widget _buildGroupedList(List<Map<String, dynamic>> users) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var user in users) {
      String key;
      if (roleFilter == 'student') {
        key = user['classId']?.toString() ?? 'Unassigned';
        // Only show groups for classes that are in the master list OR Unassigned
        if (key != 'Unassigned' && !AppConstants.schoolClasses.contains(key)) continue;
        if (key != 'Unassigned') key = 'Class $key';
      } else {
        key = user['passedOutSession']?.toString() ?? 'Unknown Session';
        if (key != 'Unknown Session') key = 'Session $key';
      }
      grouped.putIfAbsent(key, () => []).add(user);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      if (roleFilter == 'passed_out') return b.compareTo(a);
      
      // Sort students based on AppConstants.schoolClasses order
      final classA = a.replaceFirst('Class ', '');
      final classB = b.replaceFirst('Class ', '');
      
      final indexA = AppConstants.schoolClasses.indexOf(classA);
      final indexB = AppConstants.schoolClasses.indexOf(classB);
      
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      
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

  const UserCard({super.key, required this.user, required this.roleFilter});

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
                  _CircleToolButton(
                    icon: Icons.key_outlined,
                    color: Colors.orange,
                    onTap: () {
                      final state = context.findAncestorStateOfType<_UserManagementScreenState>();
                      if (state != null) state._showPasswordDialog(context, user);
                    },
                    tooltip: 'View Password',
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
                  ] else ...[
                    if (roleFilter != 'student') ...[
                      _CircleToolButton(
                        icon: Icons.security,
                        color: Colors.indigo,
                        onTap: () {
                          final state = context.findAncestorStateOfType<_UserManagementScreenState>();
                          if (state != null) state._showPermissionsDialog(context, user);
                        },
                        tooltip: 'Permissions',
                      ),
                      const SizedBox(width: 8),
                    ],
                    _CircleToolButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () {
                        final state = context.findAncestorStateOfType<_UserManagementScreenState>();
                        if (state != null) state._confirmDelete(context, user);
                      },
                      tooltip: 'Reject',
                    ),
                  ],
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

class _PermissionsDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  const _PermissionsDialog({required this.user});

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late Map<String, dynamic> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = Map<String, dynamic>.from(widget.user['permissions'] ?? {});
  }

  List<Map<String, dynamic>> _getModulesForRole(String role) {
    if (role == 'teacher') {
      return [
        {'key': 'class_details', 'label': 'Class Details', 'icon': Icons.class_outlined},
        {'key': 'attendance', 'label': 'Attendance', 'icon': Icons.how_to_reg},
        {'key': 'homework', 'label': 'Homework', 'icon': Icons.menu_book},
        {'key': 'announcements', 'label': 'Announcements', 'icon': Icons.campaign},
        {'key': 'contact_parents', 'label': 'Contact Parents', 'icon': Icons.contact_phone},
        {'key': 'salary_payment', 'label': 'Salary/Payment', 'icon': Icons.payments},
        {'key': 'my_attendance', 'label': 'My Attendance', 'icon': Icons.event_available},
        {'key': 'apply_leave', 'label': 'Apply Leave', 'icon': Icons.time_to_leave},
        {'key': 'create_test', 'label': 'Create Test', 'icon': Icons.quiz},
        {'key': 'go_live', 'label': 'Go Live', 'icon': Icons.live_tv},
        {'key': 'complaint_box', 'label': 'Complaint Box', 'icon': Icons.report_problem},
        {'key': 'exam_results', 'label': 'Exam Results', 'icon': Icons.grade},
        {'key': 'view_syllabus', 'label': 'View Syllabus', 'icon': Icons.import_contacts},
      ];
    } else if (role == 'management' || role == 'staff' || role == 'admin' || role == 'principal') {
      return [
        {'key': 'attendance', 'label': 'Attendance', 'icon': Icons.how_to_reg},
        {'key': 'fee_mgmt', 'label': 'Fee Mgmt', 'icon': Icons.account_balance_wallet},
        {'key': 'exams', 'label': 'Exams', 'icon': Icons.assignment},
        {'key': 'exam_setup', 'label': 'Exam Setup', 'icon': Icons.settings_suggest},
        {'key': 'routine', 'label': 'Routine', 'icon': Icons.schedule},
        {'key': 'announcements', 'label': 'Announcements', 'icon': Icons.campaign},
        {'key': 'complaint_box', 'label': 'Complaint Box', 'icon': Icons.report_problem},
        {'key': 'user_management', 'label': 'User Mgmt', 'icon': Icons.people_outline},
        {'key': 'leave_requests', 'label': 'Leave Requests', 'icon': Icons.event_busy},
        {'key': 'scheduled_work', 'label': 'Scheduled Work', 'icon': Icons.work_history},
        {'key': 'data_center', 'label': 'Data Center', 'icon': Icons.storage},
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final modules = _getModulesForRole(widget.user['role'] ?? '');
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.modernPrimary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.modernPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.security, color: AppColors.modernPrimary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Manage Access', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text(widget.user['name'] ?? 'User', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: modules.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No toggleable modules available for this role.', style: TextStyle(color: Colors.black54)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        final isEnabled = _permissions[module['key']] ?? true; // Default true
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isEnabled ? AppColors.modernPrimary.withOpacity(0.02) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEnabled ? AppColors.modernPrimary.withOpacity(0.1) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isEnabled ? AppColors.modernPrimary.withOpacity(0.1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(module['icon'] as IconData, size: 20, color: isEnabled ? AppColors.modernPrimary : Colors.grey),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  module['label'] as String,
                                  style: TextStyle(
                                    fontSize: 15, 
                                    fontWeight: FontWeight.w600,
                                    color: isEnabled ? Colors.black87 : Colors.black45,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: isEnabled,
                                activeColor: AppColors.modernPrimary,
                                onChanged: (val) {
                                  setState(() => _permissions[module['key'] as String] = val);
                                  if (widget.user['id'] != null) {
                                     Provider.of<UserService>(context, listen: false)
                                         .updateUserPermission(widget.user['id'], module['key'] as String, val);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
