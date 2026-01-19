import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/online_class_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/online_class_model.dart';
import 'youtube_player_screen.dart';

class StudentOnlineClassListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userClassId = authService.classId;

    if (userClassId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Live Classes')),
        body: Center(child: Text("No Class Assigned")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Live Classes')),
      body: StreamBuilder<List<OnlineClass>>(
        stream: Provider.of<OnlineClassService>(context).getActiveClassesForStudent(userClassId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
           if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tv_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No live classes right now.'),
              ],
            ));
          }

          final classes = snapshot.data!;
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final onlineClass = classes[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                     backgroundColor: Colors.red,
                     child: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  title: Text(onlineClass.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('By ${onlineClass.teacherName} • Live Now'),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => YouTubePlayerScreen(onlineClass: onlineClass),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
