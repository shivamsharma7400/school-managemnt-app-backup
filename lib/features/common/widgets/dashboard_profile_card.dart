import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/drive_helper.dart';
import '../../../data/services/auth_service.dart';
import '../../profile/profile_screen.dart';

class DashboardProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        final name = data['name'] ?? 'User';
        final role = data['role'] ?? 'Student';
        final classId = data['classId'];
        final photoUrl = DriveHelper.getDirectDriveUrl(data['photoUrl']?.toString() ?? '');
        final displayId = (role == 'teacher') 
            ? (data['teacherId'] != null ? 'ID: ${data['teacherId']}' : null)
            : (data['admNo'] != null ? 'Adm: ${data['admNo']}' : null);

        if (classId != null && role == 'student') {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('classes').doc(classId).get(),
            builder: (context, classSnapshot) {
              String displayClass = 'Class $classId';
              
              // 1. Try to get section from user's explicit profile or customData first
              dynamic sec = data['sec'] ?? data['section'];
              if (sec == null && data['customData'] != null && data['customData'] is Map) {
                sec = data['customData']['Sec'] ?? data['customData']['section'] ?? data['customData']['sec'];
              }
              String secStr = sec?.toString().trim() ?? '';
              
              if (classSnapshot.hasData && classSnapshot.data!.exists) {
                final classData = classSnapshot.data!.data() as Map<String, dynamic>;
                final className = classData['name']?.toString() ?? classId;
                
                // If className has a hyphen (e.g. "10-A"), try to format it nicely
                if (className.contains('-')) {
                  final parts = className.split('-');
                  if (parts.length > 1) {
                    displayClass = 'Class ${parts[0].trim()} - Sec ${parts[1].trim()}';
                    secStr = ''; // Unset local sec since it is encoded in class name
                  } else {
                    displayClass = 'Class $className';
                  }
                } else {
                  displayClass = 'Class $className';
                }
              }

              // Append local section if established and not already in class name
              if (secStr.isNotEmpty) {
                displayClass += ' - Sec $secStr';
              }

              return _buildCardContent(context, name, role, displayClass, photoUrl, displayId);
            },
          );
        }

        final className = role.toUpperCase();
        return _buildCardContent(context, name, role, className, photoUrl, displayId);
      },
    );
  }

  Widget _buildCardContent(BuildContext context, String name, String role, String className, String? photoUrl, String? displayId) {
    return Container(
      decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[800]!, Colors.blue[600]!],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.to(() => ProfileScreen()),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                name[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back,',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              className,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (displayId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              displayId,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}
