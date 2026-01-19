
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
    return _classNames[classId] ?? 'Unknown Class'; // Fallback to ID if not found? No, looks bad. 'Unknown Class' is better or just 'Class'
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(student['name'] ?? 'Unknown Name', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.class_, color: Colors.grey),
                  SizedBox(width: 8),
                  Text("Class: ${_getClassName(student['classId'])}", style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(child: Text("Address: ${student['address'] ?? 'Not Available'}", style: TextStyle(fontSize: 16))),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.message), 
                label: Text("Continue with WhatsApp"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12)
                ),
                onPressed: () => _launchWhatsApp(student['mobileNumber']),
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.email),
                label: Text("Continue with Email"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12)
                ),
                onPressed: () => _launchEmail(student['email']),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchWhatsApp(String? mobile) async {
    if (mobile == null || mobile.isEmpty) {
      _showError("Mobile number not available");
      return;
    }
    // Remove non-digits/ensure international format if needed. 
    // Assuming Indian numbers +91 or raw 10 digit.
    // If raw 10 digit, append 91? Let's check user intent. Usually better to just try.
    // Making it safe:
    String cleanNumber = mobile.replaceAll(RegExp(r'\D'), ''); 
    if (cleanNumber.length == 10) cleanNumber = "91$cleanNumber"; // Default to India if 10 digits

    final Uri url = Uri.parse("https://wa.me/$cleanNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError("Could not launch WhatsApp");
    }
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) {
      _showError("Email not available");
      return;
    }
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Message from Teacher',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      _showError("Could not launch Email app");
    }
  }

  void _showError(String msg) {
    if(!mounted) return;
    Navigator.pop(context); // Close bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Write to Student")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search Student Name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
              ),
              onChanged: (val) => _performSearch(val),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty 
                ? Center(child: Text("No students found"))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final student = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text(student['name'] ?? 'Unknown'),
                        subtitle: Text("Class: ${_getClassName(student['classId'])}"),
                        onTap: () => _showStudentDetails(student),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
