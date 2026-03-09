import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../settings/settings_screen.dart';
import '../../core/utils/drive_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _classController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  String? _selectedGender;
  String? _photoUrl;
  String? _role;
  String? _id; // Adm No or Teacher ID
  String? _classTeacherName;
  String? _section;
  String? _rollNo;
  bool _isEditing = false;
  bool _isLoading = true;

  late TextEditingController _fatherNameController;
  late TextEditingController _motherNameController;
  late TextEditingController _aadharController;
  late TextEditingController _ifscController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankHolderController;
  late TextEditingController _pinCodeController;
  late TextEditingController _resumeLinkController;
  late TextEditingController _teachingSubjectController;
  late TextEditingController _workFieldController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _classController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    
    // New fields
    _fatherNameController = TextEditingController();
    _motherNameController = TextEditingController();
    _aadharController = TextEditingController();
    _ifscController = TextEditingController();
    _bankAccountController = TextEditingController();
    _bankNameController = TextEditingController();
    _bankHolderController = TextEditingController();
    _pinCodeController = TextEditingController();
    _resumeLinkController = TextEditingController();
    _teachingSubjectController = TextEditingController();
    _workFieldController = TextEditingController();

    _fetchUserData();
  }

  void _fetchUserData() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _role = data['role'];
        _nameController.text = data['name'] ?? '';
        _classController.text = data['classId'] != null
            ? 'Class ${data['classId']}'
            : '';
        _phoneController.text = data['phone'] ?? '';
        _dobController.text = data['dob'] ?? data['age'] ?? '';
        _addressController.text = data['address'] ?? '';
        _selectedGender = data['gender'];
        _photoUrl = DriveHelper.getDirectDriveUrl(data['photoUrl']?.toString() ?? '');
        _id = data['role'] == 'teacher' ? data['teacherId'] : data['admNo'];

        // Initializing new fields
        _fatherNameController.text = data['fatherName'] ?? '';
        _motherNameController.text = data['motherName'] ?? '';
        _aadharController.text = data['aadharNo'] ?? '';
        _ifscController.text = data['ifscCode'] ?? '';
        _bankAccountController.text = data['bankAccountNo'] ?? '';
        _bankNameController.text = data['bankName'] ?? '';
        _bankHolderController.text = data['bankHolderName'] ?? '';
        _pinCodeController.text = data['pinCode'] ?? '';
        _resumeLinkController.text = data['resumeLink'] ?? '';
        _teachingSubjectController.text = data['teachingSubject'] ?? '';
        _workFieldController.text = data['workField'] ?? '';

        // If teacher, fetch class they are in charge of
        if (_role == 'teacher') {
          final classDoc = await FirebaseFirestore.instance
              .collection('classes')
              .where('teacherId', isEqualTo: user.uid)
              .limit(1)
              .get();
          if (classDoc.docs.isNotEmpty) {
            _classController.text = 'Class ${classDoc.docs.first['name']}';
          } else {
            _classController.text = 'Not assigned';
          }
        } else if (_role == 'student' && data['classId'] != null) {
          // Fetch Class details to get exact class name, section, and teacher
          try {
            final classDoc = await FirebaseFirestore.instance
                .collection('classes')
                .doc(data['classId'])
                .get();
            if (classDoc.exists) {
              final classData = classDoc.data()!;
              final className = classData['name']?.toString() ?? '';
              
              // Basic Section extraction if format is "Grade-Section"
              if (className.contains('-')) {
                final parts = className.split('-');
                if (parts.length > 1) {
                  _section = parts[1].trim();
                }
              }

              // Fetch Class Teacher Name
              final teacherId = classData['teacherId'];
              if (teacherId != null && teacherId.toString().isNotEmpty) {
                final teacherDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(teacherId)
                    .get();
                if (teacherDoc.exists) {
                  _classTeacherName = teacherDoc.data()?['name'];
                }
              }
            }
          } catch (e) {
            print("Error fetching class details: $e");
          }
          
          // Fallback: Check user profile explicit 'sec' or 'section'
          if (_section == null || _section!.isEmpty) {
            _section = data['sec'] ?? data['section'];
          }
          
          // Get Roll Number and Section from customData if they exist
          if (data['customData'] != null && data['customData'] is Map) {
             _rollNo = data['customData']['Roll.no']?.toString() ?? _rollNo;
             if (_section == null || _section!.isEmpty) {
               _section = data['customData']['Sec'] ?? data['customData']['section'] ?? data['customData']['sec'];
             }
          }
        }
      }
    }
    setState(() => _isLoading = false);
  }

  void _showPhotoUpdateDialog() {
    final TextEditingController linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Profile Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paste Google Drive Image Link:', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: linkController,
              decoration: InputDecoration(
                hintText: 'https://drive.google.com/...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the link is set to "Anyone with the link can view"',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange[800], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              String rawUrl = linkController.text.trim();
              if (rawUrl.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                final user = Provider.of<AuthService>(context, listen: false).user;
                if (user != null) {
                  await Provider.of<UserService>(context, listen: false).updateProfile(
                    user.uid, 
                    {'photoUrl': rawUrl} // We save raw, getDirectDriveUrl handles it in fetch
                  );
                  _fetchUserData(); // Refresh
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('UPDATE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.blueAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(authService),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Personal Information', Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildInfoCard([
                            _buildInfoTile(
                              label: 'Full Name',
                              controller: _nameController,
                              icon: Icons.badge_outlined,
                              enabled: false,
                            ),
                            if (_role == 'student' && _classController.text.isNotEmpty)
                              _buildInfoTile(
                                label: 'Class',
                                controller: _classController,
                                icon: Icons.school_outlined,
                                enabled: false,
                              ),
                            if (_role == 'student' && _section != null && _section!.isNotEmpty)
                              _buildInfoTile(
                                label: 'Section',
                                controller: TextEditingController(text: _section),
                                icon: Icons.meeting_room,
                                enabled: false,
                              ),
                            if (_role == 'student')
                              _buildInfoTile(
                                label: 'Roll Number',
                                controller: TextEditingController(text: _rollNo ?? 'N/A'),
                                icon: Icons.format_list_numbered,
                                enabled: false,
                              ),
                            if (_role == 'student' && _classTeacherName != null)
                              _buildInfoTile(
                                label: 'Class Teacher',
                                controller: TextEditingController(text: _classTeacherName),
                                icon: Icons.person_pin,
                                enabled: false,
                              ),
                            if (_role == 'teacher')
                              _buildInfoTile(
                                label: 'Class Teacher',
                                controller: _classController,
                                icon: Icons.school_outlined,
                                enabled: false,
                              ),
                            _buildInfoTile(
                              label: 'Phone Number',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                            ),
                            if (_id != null)
                              _buildInfoTile(
                                label: _role == 'teacher' ? 'Teacher ID' : 'Admission Number',
                                controller: TextEditingController(text: _id),
                                icon: Icons.fingerprint,
                                enabled: false,
                              ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Other Details', Icons.info_outline),
                          const SizedBox(height: 16),
                          _buildInfoCard([
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _isEditing ? () => _selectDate(context) : null,
                                    child: IgnorePointer(
                                      child: _buildInfoTile(
                                        label: 'Date of Birth',
                                        controller: _dobController,
                                        icon: Icons.cake_outlined,
                                        enabled: _isEditing,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildGenderDropdown(),
                                ),
                              ],
                            ),
                            _buildInfoTile(
                              label: 'Address',
                              controller: _addressController,
                              icon: Icons.home_outlined,
                              enabled: _isEditing,
                              maxLines: 3,
                            ),
                          ]),
                          const SizedBox(height: 40),
                          if (_isEditing)
                            Center(
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'SAVE CHANGES',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Form(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_role == 'student') ...[
                            const SizedBox(height: 24),
                            _buildSectionHeader('Family Details', Icons.family_restroom),
                            const SizedBox(height: 16),
                            _buildInfoCard([
                              _buildInfoTile(
                                label: "Father's Name",
                                controller: _fatherNameController,
                                icon: Icons.person,
                                enabled: _isEditing,
                              ),
                              _buildInfoTile(
                                label: "Mother's Name",
                                controller: _motherNameController,
                                icon: Icons.person_outline,
                                enabled: _isEditing,
                              ),
                            ]),
                          ],

                          const SizedBox(height: 24),
                          _buildSectionHeader('Professional & Legal', Icons.work_outline),
                          const SizedBox(height: 16),
                          _buildInfoCard([
                             _buildInfoTile(
                                label: 'Aadhar Number',
                                controller: _aadharController,
                                icon: Icons.credit_card,
                                enabled: _isEditing,
                                keyboardType: TextInputType.number,
                              ),
                             if (_role != 'student')
                                _buildInfoTile(
                                  label: 'Resume Link (Google Drive)',
                                  controller: _resumeLinkController,
                                  icon: Icons.link,
                                  enabled: _isEditing,
                                ),
                             if (_role == 'teacher')
                                _buildInfoTile(
                                  label: 'Teaching Subject',
                                  controller: _teachingSubjectController,
                                  icon: Icons.menu_book,
                                  enabled: _isEditing,
                                ),
                              if (_role == 'staff')
                                _buildInfoTile(
                                  label: 'Work Field',
                                  controller: _workFieldController,
                                  icon: Icons.work,
                                  enabled: _isEditing,
                                ),
                          ]),

                          const SizedBox(height: 24),
                          _buildSectionHeader('Banking Details', Icons.account_balance),
                          const SizedBox(height: 16),
                          _buildInfoCard([
                              _buildInfoTile(
                                label: 'Bank Name',
                                controller: _bankNameController,
                                icon: Icons.account_balance,
                                enabled: _isEditing,
                              ),
                              _buildInfoTile(
                                label: 'Account Holder Name',
                                controller: _bankHolderController,
                                icon: Icons.person,
                                enabled: _isEditing,
                              ),
                              _buildInfoTile(
                                label: 'Account Number',
                                controller: _bankAccountController,
                                icon: Icons.numbers,
                                enabled: _isEditing,
                                keyboardType: TextInputType.number,
                              ),
                              _buildInfoTile(
                                label: 'IFSC Code',
                                controller: _ifscController,
                                icon: Icons.qr_code,
                                enabled: _isEditing,
                              ),
                              if (_role == 'student')
                                _buildInfoTile(
                                  label: 'PIN Code',
                                  controller: _pinCodeController,
                                  icon: Icons.pin_drop,
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.number,
                                ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: _isEditing 
                    ? Center(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 5,
                          ),
                          child: Text(
                            'SAVE CHANGES',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar(AuthService authService) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Premium Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[900]!,
                    Colors.blue[600]!,
                    Colors.blue[400]!,
                  ],
                ),
              ),
            ),
            // Subtle Pattern overlay if possible, or just a radial gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'profile_pic',
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                            child: _photoUrl == null
                                ? Text(
                                    _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                                    style: GoogleFonts.poppins(fontSize: 45, color: Colors.blue[900], fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        if (['admin', 'principal', 'management'].contains(_role))
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _showPhotoUpdateDialog,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black26, blurRadius: 10),
                                  ],
                                ),
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Text(
                          (_role ?? 'USER').toUpperCase(),
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ),
                      if (_role == 'passed_out') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            'PASSED OUT',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())),
          ),
        IconButton(
          icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, color: Colors.white),
          onPressed: () => setState(() => _isEditing = !_isEditing),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 22),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children.expand((w) => [w, const SizedBox(height: 20)]).toList()..removeLast(),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.blueGrey[800], fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            prefixIcon: Icon(icon, size: 20, color: enabled ? Colors.blueAccent : Colors.grey[400]),
            prefixIconConstraints: BoxConstraints(minWidth: 40),
            border: InputBorder.none,
            disabledBorder: InputBorder.none,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            prefixIcon: Icon(Icons.wc_outlined, size: 20, color: _isEditing ? Colors.blueAccent : Colors.grey[400]),
            prefixIconConstraints: BoxConstraints(minWidth: 40),
            border: InputBorder.none,
            enabled: _isEditing,
          ),
          icon: _isEditing ? Icon(Icons.arrow_drop_down, color: Colors.blueAccent) : SizedBox.shrink(),
          items: ['Male', 'Female', 'Other'].map((String gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(gender, style: GoogleFonts.poppins(fontSize: 16, color: Colors.blueGrey[800], fontWeight: FontWeight.w600)),
            );
          }).toList(),
          onChanged: _isEditing ? (val) => setState(() => _selectedGender = val) : null,
        ),
      ],
    );
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      final Map<String, dynamic> updateData = {
        'phone': _phoneController.text,
        'dob': _dobController.text,
        'gender': _selectedGender,
        'address': _addressController.text,
        
        // Banking & Common
        'aadharNo': _aadharController.text,
        'ifscCode': _ifscController.text,
        'bankAccountNo': _bankAccountController.text,
        'bankName': _bankNameController.text,
        'bankHolderName': _bankHolderController.text,
      };

      if (_role == 'student') {
        updateData['fatherName'] = _fatherNameController.text;
        updateData['motherName'] = _motherNameController.text;
        updateData['pinCode'] = _pinCodeController.text;
      } else {
        updateData['resumeLink'] = _resumeLinkController.text;
        if (_role == 'teacher') {
          updateData['teachingSubject'] = _teachingSubjectController.text;
        } else if (_role == 'staff') {
          updateData['workField'] = _workFieldController.text;
        }
      }

      await Provider.of<UserService>(
        context,
        listen: false,
      ).updateProfile(user.uid, updateData);
    }
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile Updated Successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
