import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _classController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;
  String? _selectedGender;
  String? _photoUrl;
  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _classController = TextEditingController();
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _addressController = TextEditingController();
    _fetchUserData();
  }

  void _fetchUserData() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _classController.text = data['classId'] != null ? 'Class ${data['classId']}' : ''; 
        _phoneController.text = data['phone'] ?? '';
        _ageController.text = data['age'] ?? '';
        _addressController.text = data['address'] ?? '';
        _selectedGender = data['gender']; 
        _photoUrl = data['photoUrl'];
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          )
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                     CircleAvatar(
                       radius: 50,
                       backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                       child: _photoUrl == null ? Text(authService.user?.email?[0].toUpperCase() ?? "U", style: TextStyle(fontSize: 40)) : null,
                     ),
                     SizedBox(height: 16),
                     Text(authService.user?.email ?? "", style: Theme.of(context).textTheme.titleMedium),
                     SizedBox(height: 24),
                     TextFormField(
                       controller: _nameController,
                       decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                       enabled: false, 
                     ),
                     if (_classController.text.isNotEmpty) ...[
                       SizedBox(height: 16),
                       TextFormField(
                         controller: _classController,
                         decoration: InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                         enabled: false,
                       ),
                     ],
                     SizedBox(height: 16),
                     TextFormField(
                       controller: _phoneController,
                       decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                       enabled: _isEditing,
                       keyboardType: TextInputType.phone,
                     ),
                     SizedBox(height: 16),
                     Row(
                       children: [
                         Expanded(
                           child: TextFormField(
                             controller: _ageController,
                             decoration: InputDecoration(labelText: 'Age (Aadhar)', border: OutlineInputBorder()),
                             enabled: _isEditing,
                             keyboardType: TextInputType.number,
                           ),
                         ),
                         SizedBox(width: 16),
                         Expanded(
                           child: DropdownButtonFormField<String>(
                             value: _selectedGender,
                             decoration: InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                             items: ['Male', 'Female', 'Other'].map((String gender) {
                               return DropdownMenuItem<String>(
                                 value: gender,
                                 child: Text(gender),
                               );
                             }).toList(),
                             onChanged: _isEditing ? (val) => setState(() => _selectedGender = val) : null,
                           ),
                         ),
                       ],
                     ),
                     SizedBox(height: 16),
                     TextFormField(
                       controller: _addressController,
                       decoration: InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                       enabled: _isEditing,
                       maxLines: 3,
                     ),
                  ],
                ),
              ),
            ),
    );
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      await Provider.of<UserService>(context, listen: false).updateProfile(user.uid, {
        'phone': _phoneController.text,
        'age': _ageController.text,
        'gender': _selectedGender,
        'address': _addressController.text,
      });
    }
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile Updated')));
  }
}
