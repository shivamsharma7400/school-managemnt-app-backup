import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vps/data/services/auth_service.dart';
import 'package:vps/core/constants/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _workController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _obscurePassword = true;

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
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
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

  void _register(String requestedRole) async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    Map<String, dynamic> additionalData = {
      'phone': _phoneController.text.trim(),
      'dob': _dobController.text.trim(),
      'gender': _selectedGender,
      'address': _addressController.text.trim(),
      'work': _workController.text.trim(),
      'requestedRole': requestedRole,
    };

    String? error = await authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      'pending',
      additionalData,
    );
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  Colors.white,
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 40 : 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1100 : 500,
                  ),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isDesktop)
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: AppColors.primary.withOpacity(0.02),
                                padding: EdgeInsets.all(40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Welcome to VPS",
                                      style: GoogleFonts.outfit(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Join our community and start your journey towards excellence today.",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    SizedBox(height: 40),
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/registration_bg.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Expanded(
                            flex: isDesktop ? 1 : 1,
                            child: Padding(
                              padding: EdgeInsets.all(isDesktop ? 40 : 24),
                              child: DefaultTabController(
                                length: 3,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Create Account",
                                      style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onBackground,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Fill in your details to get started",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.all(6),
                                      child: TabBar(
                                        dividerColor: Colors.transparent,
                                        indicatorSize: TabBarIndicatorSize.tab,
                                        indicator: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        labelColor: AppColors.primary,
                                        unselectedLabelColor: Colors.black54,
                                        labelStyle: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        unselectedLabelStyle: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        tabs: [
                                          Tab(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.school_outlined, size: 18),
                                                SizedBox(width: 8),
                                                Text('Student'),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.person_outline, size: 18),
                                                SizedBox(width: 8),
                                                Text('Teacher'),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.badge_outlined, size: 18),
                                                SizedBox(width: 8),
                                                Text('Staff'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    Flexible(
                                      child: SizedBox(
                                        height: 500, // Fixed height for TabBarView to work inside scrollable
                                        child: TabBarView(
                                          children: [
                                            _buildRegisterForm('student'),
                                            _buildRegisterForm('teacher'),
                                            _buildRegisterForm('staff'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          "Already have an account? Login",
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegisterForm(String role) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(_nameController, 'Full Name', Icons.person_outline),
          SizedBox(height: 16),
          _buildTextField(_emailController, AppStrings.email, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          SizedBox(height: 16),
          _buildTextField(_phoneController, 'Mobile Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                    hintText: 'DD/MM/YYYY',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  style: GoogleFonts.outfit(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_outlined, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: ['Male', 'Female', 'Other'].map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val!),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTextField(_addressController, 'Address (Aadhar)', Icons.home_outlined, maxLines: 2),
          if (role != 'student') ...[
            SizedBox(height: 16),
            _buildTextField(_workController, 'Work / Responsibility', Icons.work_outline),
          ],
          SizedBox(height: 16),
          _buildPasswordField(),
          SizedBox(height: 32),
          _buildSubmitButton(role),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.outfit(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      style: GoogleFonts.outfit(),
      decoration: InputDecoration(
        labelText: AppStrings.password,
        prefixIcon: Icon(Icons.lock_outlined, size: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      obscureText: _obscurePassword,
    );
  }

  Widget _buildSubmitButton(String role) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _register(role),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Text(
                'Register as ${role[0].toUpperCase()}${role.substring(1)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
