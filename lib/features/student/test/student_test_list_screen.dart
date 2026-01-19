import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/test_model.dart';
import '../../../data/services/test_service.dart';
import '../../../data/services/auth_service.dart';
import 'test_taking_screen.dart';

class StudentTestListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userClassId = authService.classId;

    if (userClassId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Online Tests')),
        body: Center(child: Text("No Class Assigned")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Online Tests')),
      body: StreamBuilder<List<Test>>(
        stream: Provider.of<TestService>(context).getTestsForClass(userClassId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
           if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tests available for your class.'));
          }

          final tests = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepOrangeAccent,
                    child: Icon(Icons.quiz, color: Colors.white),
                  ),
                  title: Text(test.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${test.subject} • ${test.durationMinutes} mins • ${test.questions.length} Questions"),
                  trailing: ElevatedButton(
                    onPressed: () => _checkAndStartTest(context, test),
                    child: Text('Start'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _checkAndStartTest(BuildContext context, Test test) async {
    // Check if already taken
    final authService = Provider.of<AuthService>(context, listen: false);
    final testService = Provider.of<TestService>(context, listen: false);
    
    // Simple alert to confirm
    bool confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text('Start Test?'),
        content: Text("You are about to start '${test.title}'.\n\nRules:\n1. Do not switch apps.\n2. Do not minimize.\n3. Screenshots are disabled.\n\nViolation will auto-submit the test."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Start')),
        ],
      )
    ) ?? false;

    if (confirm) {
        final taken = await testService.hasStudentTakenTest(test.id, authService.user!.uid);
        if (taken) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You have already taken this test.')));
           return;
        }

        Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => TestTakingScreen(test: test))
        );
    }
  }
}
