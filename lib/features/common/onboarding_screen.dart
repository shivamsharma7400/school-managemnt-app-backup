import 'package:flutter/material.dart';
import '../../main.dart'; // For AuthWrapper
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Welcome to VPS App",
      "body": "Your one-stop solution for managing school activities, fees, and results.",
      "icon": "school" 
    },
    {
      "title": "Track Attendance",
      "body": "Stay updated with your daily class attendance and never miss a beat.",
      "icon": "calendar_today"
    },
    {
      "title": "Instant Results",
      "body": "View your exam results and performance analysis instantly.",
      "icon": "assignment"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (val) => setState(() => _currentPage = val),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIcon(_pages[index]['icon']!),
                          size: 120,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 40),
                        Text(
                          _pages[index]['title']!,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Text(
                          _pages[index]['body']!,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: EdgeInsets.all(4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthWrapper()));
                    } else {
                      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text(_currentPage == _pages.length - 1 ? "Get Started" : "Next"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'school': return Icons.school;
      case 'calendar_today': return Icons.calendar_today;
      case 'assignment': return Icons.assignment_turned_in;
      default: return Icons.info;
    }
  }
}
