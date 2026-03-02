import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../../main.dart'; // For AuthWrapper
import 'package:provider/provider.dart';
import 'package:vps/core/constants/app_constants.dart'; // Import AppStrings
import 'package:vps/data/services/school_config_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    // Navigate to Login Screen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      // Navigator.pushReplacementNamed(context, '/login'); // Use named route if defined
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthWrapper()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We can listen here, or just fetch once since splash is short lived.
    // However, listening ensures we get the latest if cached.
    final config = Provider.of<SchoolConfigService>(context);

    return Scaffold(
      backgroundColor: Colors.blueAccent, // Use your primary color
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              // Logo
               Container(
                 width: 120,
                 height: 120,
                 decoration: BoxDecoration(
                   color: Colors.white,
                   shape: BoxShape.circle,
                 ),
                 child: Image.asset('assets/logos/logo.png', height: 80),
               ),
              SizedBox(height: 20),
              // App Name
              Text(
                config.schoolName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 10),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
