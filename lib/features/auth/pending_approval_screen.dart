
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../student/explore/explore_school_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Approval Pending')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Your account is pending approval.',
                 style: Theme.of(context).textTheme.headlineSmall,
                 textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please contact the school administration.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
                child: Text('Logout'),
              ),
              SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.travel_explore),
                label: Text('Explore School'),
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => ExploreSchoolScreen()));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
