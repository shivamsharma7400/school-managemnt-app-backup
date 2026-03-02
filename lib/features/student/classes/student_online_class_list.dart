import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/online_class_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/online_class_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'youtube_player_screen.dart';

class StudentOnlineClassListScreen extends StatelessWidget {
  const StudentOnlineClassListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userClassId = authService.classId;

    if (userClassId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('E-Content', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text("No Class Assigned", style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('E-Content', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _buildClassList(context, userClassId),
    );
  }

  Widget _buildClassList(BuildContext context, String classId) {
    final service = Provider.of<OnlineClassService>(context, listen: false);
    return StreamBuilder<List<OnlineClass>>(
      stream: service.getAllClassesForStudent(classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_collection_outlined, 
                  size: 64, 
                  color: Colors.grey[300]
                ),
                const SizedBox(height: 16),
                Text(
                  'No E-Content available yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        final classes = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              // Responsive GridView for Desktop/Tablet
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth > 1200 ? 4 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, // Adjust based on your card content
                ),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  return _buildClassCard(context, classes[index]);
                },
              );
            } else {
              // Standard ListView for Mobile
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildClassCard(context, classes[index]),
                  );
                },
              );
            }
          }
        );
      },
    );
  }

  Widget _buildClassCard(BuildContext context, OnlineClass cls) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YouTubePlayerScreen(onlineClass: cls),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black87,
                    child: Image.network(
                      'https://img.youtube.com/vi/${cls.youtubeVideoId}/maxresdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                      ),
                    ),
                  ),
                ),
                FutureBuilder<yt.Video>(
                  future: yt.YoutubeExplode().videos.get(cls.youtubeVideoId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isLive) {
                      return Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 4),
                              Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cls.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Spacer(), // Push the bottom row down in GridView
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.indigo[50],
                          child: Text(cls.teacherName[0], style: const TextStyle(fontSize: 10, color: Colors.indigo)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'By ${cls.teacherName}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${cls.startedAt.day}/${cls.startedAt.month}/${cls.startedAt.year}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
