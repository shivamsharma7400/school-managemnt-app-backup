import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';

class DevSchoolInfoScreen extends StatefulWidget {
  const DevSchoolInfoScreen({super.key});

  @override
  State<DevSchoolInfoScreen> createState() => _DevSchoolInfoScreenState();
}

class _DevSchoolInfoScreenState extends State<DevSchoolInfoScreen> {
  static const Color devPrimary = Colors.blueAccent; 
  static const Color devAccent = Colors.greenAccent; 

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSchoolInfo();
  }

  Future<void> _fetchSchoolInfo() async {
    try {
      // Nothing to fetch for now as everything is centralized
    } catch (e) {
      debugPrint("Error fetching config: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchoolInfo() async {
    // Nothing to save for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration is now centralized in AppConstants.'), backgroundColor: devAccent),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: devPrimary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance, color: devPrimary, size: 32),
                  const SizedBox(width: 16),
                  Text(
                    'SCHOOL CONFIGURATION',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '// Global settings controlling default parameters for deployed apps.',
                style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
              const SizedBox(height: 48),

              // Logo Display
              _buildSectionCard(
                title: 'GLOBAL LOGO',
                icon: Icons.image,
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        border: Border.all(color: devPrimary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/logos/logo.png', 
                          fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => const Icon(Icons.school, color: Colors.white24, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ASSET BUNDLE LOGO",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "This logo is hardcoded into the asset bundle ('assets/logos/logo.png') and is entirely read-only. It cannot be modified via the cloud database.",
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Academic Classes (Centralized Info)
               _buildSectionCard(
                title: 'ACADEMIC CLASSES (Hardcoded)',
                icon: Icons.list_alt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "The following classes are now centralized in AppConstants.schoolClasses:",
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.schoolClasses.map((c) => Chip(
                        label: Text(c, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: devPrimary.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: devPrimary.withOpacity(0.3)),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Save Button (Not needed anymore but keeping UI consistency)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Configuration is now centralized in AppConstants.'), backgroundColor: devAccent),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white12),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                  ),
                  child: Text(
                          'GLOBAL CONFIG IS NOW READ-ONLY (CENTRALIZED)',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: devPrimary.withOpacity(0.5), size: 18),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: devPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.3), fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: devPrimary.withOpacity(0.5)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
