
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/user_service.dart';
import '../../data/services/class_service.dart';

class StudentSearchScreen extends StatefulWidget {
  @override
  _StudentSearchScreenState createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, String> _classNames = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _performSearch('');
  }

  Future<void> _loadClasses() async {
    final classes = await Provider.of<ClassService>(context, listen: false).fetchAllClasses();
    if (mounted) {
      setState(() {
        _classNames = {for (var c in classes) c.id: c.name};
      });
    }
  }

  void _performSearch(String query) async {
    setState(() => _isLoading = true);
    final results = await Provider.of<UserService>(context, listen: false).searchStudents(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  String _getClassName(String? classId) {
    if (classId == null) return 'Not Assigned';
    return _classNames[classId] ?? 'Unknown Class';
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    // Standardize phone field access
    final String? phoneNumber = student['phone'] ?? student['mobileNumber'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                   CircleAvatar(
                     radius: 30,
                     backgroundColor: Colors.blue.withOpacity(0.1),
                     child: const Icon(Icons.person, size: 36, color: Colors.blue),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           student['name'] ?? 'Unknown Student',
                           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                         ),
                         Text(
                           "Class: ${_getClassName(student['classId'])}",
                           style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.blueGrey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      student['address'] ?? 'Address not available',
                      style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   const Icon(Icons.phone_outlined, color: Colors.blueGrey, size: 20),
                   const SizedBox(width: 12),
                   Text(
                     phoneNumber ?? 'No phone number available',
                     style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                   ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.call, size: 24), 
                  label: const Text("CALL PARENTS", style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600], 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Colors.green.withOpacity(0.4),
                  ),
                  onPressed: () => _launchPhoneCall(phoneNumber),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchPhoneCall(String? mobile) async {
    if (mobile == null || mobile.isEmpty) {
      _showError("Phone number not available for this student");
      return;
    }
    
    final String cleanNumber = mobile.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse("tel:$cleanNumber");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showError("Could not launch dialer");
    }
  }

  void _showError(String msg) {
    if(!mounted) return;
    // Check if bottom sheet is open before popping
    if (Navigator.canPop(context)) {
      Navigator.pop(context); 
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Contact Parents", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search student to call parents...",
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              ),
              onChanged: (val) => _performSearch(val),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty 
                ? const Center(child: Text("No students found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final student = _searchResults[index];
                      final String? phoneNumber = student['phone'] ?? student['mobileNumber'];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(
                            student['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "Class: ${_getClassName(student['classId'])}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (phoneNumber != null)
                                Text(
                                  phoneNumber,
                                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call, color: Colors.green, size: 20),
                          ),
                          onTap: () => _showStudentDetails(student),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
