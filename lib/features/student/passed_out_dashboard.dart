
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';

class PassedOutDashboard extends StatelessWidget {
  const PassedOutDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;
    final session = user?['passedOutSession'] ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(40),
          margin: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school, size: 80, color: Colors.green),
              ),
              SizedBox(height: 32),
              Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'You have been passed out from school',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Passing Session: ',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    session,
                    style: TextStyle(
                      color: AppColors.modernPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => authService.signOut(),
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.modernPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
