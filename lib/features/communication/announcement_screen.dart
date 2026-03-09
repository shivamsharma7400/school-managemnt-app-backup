import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/ai_service.dart';

import '../../data/models/announcement_model.dart';
import '../../data/services/announcement_service.dart';
import '../../data/services/notification_service.dart';

class AnnouncementScreen extends StatelessWidget {
  const AnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userRole = authService.role ?? 'student'; // Default to student safely
    final canPost = userRole == 'principal' || userRole == 'management' || userRole == 'admin';

    return Scaffold(
      appBar: AppBar(title: Text('Announcements')),
      body: StreamBuilder<List<Announcement>>(
        // Pass userRole to filter announcements
        stream: Provider.of<AnnouncementService>(context).getAnnouncements(userRole),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No announcements yet.'));
          }

          final announcements = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];
              Color bgColor;
              IconData icon;
              Color iconColor;

              switch (item.type) {
                case 'urgent':
                  bgColor = Colors.red.shade50;
                  icon = Icons.warning_amber_rounded;
                  iconColor = Colors.red;
                  break;
                case 'event':
                  bgColor = Colors.purple.shade50;
                  icon = Icons.event;
                  iconColor = Colors.purple;
                  break;
                default:
                  bgColor = Colors.white;
                  icon = Icons.campaign_outlined;
                  iconColor = Colors.blue;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconColor.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(DateFormat('MMM d, y • h:mm a').format(item.date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      if (canPost)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            'To: ${item.targetAudience.toUpperCase()}',
                            style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(),
                          Text(item.content, style: TextStyle(height: 1.5, fontSize: 15)),
                          if (canPost)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                label: Text('Delete', style: TextStyle(color: Colors.red)),
                                onPressed: () => _confirmDelete(context, item.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: canPost
          ? FloatingActionButton(
              onPressed: () => _showAudienceSelectionDialog(context), // Start with audience selection
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Announcement?'),
        content: Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<AnnouncementService>(context, listen: false).deleteAnnouncement(id);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAudienceSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select Audience'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showAddDialog(context, 'student');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Students Only', style: TextStyle(fontSize: 16)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showAddDialog(context, 'teacher');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Teachers Only', style: TextStyle(fontSize: 16)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showAddDialog(context, 'all');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Both (All)', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, String targetAudience) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String type = 'general';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('New Announcement (${targetAudience.toUpperCase()})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    DropdownMenuItem(value: 'event', child: Text('Event')),
                  ],
                  onChanged: (val) => setState(() => type = val!),
                ),
                TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
                TextField(controller: contentController, decoration: InputDecoration(labelText: 'Content'), maxLines: 5),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(Icons.auto_awesome, color: Colors.purple),
                    label: Text('Rewrite with AI', style: TextStyle(color: Colors.purple)),
                    onPressed: () async {
                      if (contentController.text.isEmpty || titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter title and content first.')));
                        return;
                      }

                      final authService = Provider.of<AuthService>(context, listen: false);
                      final aiService = Provider.of<AIService>(context, listen: false);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI is refining your announcement...')));

                      final refinedContent = await aiService.generateAnnouncement(
                        content: contentController.text,
                        title: titleController.text,
                        senderName: authService.userName,
                        role: authService.role ?? 'Management',
                      );

                      if (refinedContent != null) {
                        contentController.text = refinedContent;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  Provider.of<AnnouncementService>(context, listen: false)
                      .addAnnouncement(titleController.text, contentController.text, type, targetAudience);
                  
                  // Trigger Notification
                  final notificationService = Provider.of<NotificationService>(context, listen: false);
                  notificationService.sendBroadcastNotification(
                    'New Announcement: ${titleController.text}', 
                    'Click to view details.',
                    targetRole: targetAudience == 'all' ? null : targetAudience
                  );
                  
                  Navigator.pop(context);
                }
              },
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
