import 'package:flutter/material.dart';
import '../../data/utils/migration_util.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background for professional feel
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Standard Configuration'),
            _buildSettingsItem(
              context: context,
              title: 'App Theme',
              subtitle: 'Current: Light Theme (Optimized)',
              icon: Icons.palette_outlined,
              iconColor: Colors.blue,
              trailing: const Text('LOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            _buildSettingsItem(
              context: context,
              title: 'Language',
              subtitle: 'Default: English',
              icon: Icons.language_rounded,
              iconColor: Colors.green,
            ),
            
            const SizedBox(height: 16),
            _buildSectionHeader('Data Management'),
            _buildSettingsItem(
              context: context,
              title: 'Sync Standard Classes',
              subtitle: 'Re-initialize all classes from Nursery to 12. Fixes missing or duplicate class records.',
              icon: Icons.sync_rounded,
              iconColor: Colors.orange,
              onTap: () => _handleSync(context),
            ),
            _buildSettingsItem(
              context: context,
              title: 'Database Statistics',
              subtitle: 'View record counts and storage health.',
              icon: Icons.bar_chart_rounded,
              iconColor: Colors.purple,
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Module under maintenance.')));
              },
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('About'),
            _buildSettingsItem(
              context: context,
              title: 'Version',
              subtitle: 'v2.1.0-beta.annual-fees',
              icon: Icons.info_outline_rounded,
              iconColor: Colors.grey[700]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.indigo[900]?.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: Colors.grey) : null),
      ),
    );
  }

  Future<void> _handleSync(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Database Synchronize'),
        content: const Text(
          'This will standardize all class IDs and ensure standard classes (Nursery-12) are correctly initialized. This might take a few moments. Proceed?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog
              
              // Show progress
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                       SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                       SizedBox(width: 15),
                       Text('Synchronizing database classes...'),
                    ],
                  ),
                  duration: Duration(minutes: 1),
                ),
              );

              try {
                await MigrationUtil.standardizeClassIds();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text('Sync complete! All standard classes are now active.')
                    )
                  );
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).clearSnackBars();
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Colors.red, content: Text('Sync failed: $e'))
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[900],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Sync Now'),
          ),
        ],
      ),
    );
  }
}
