
import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors (Modern Indigo)
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryVariant = Color(0xFF4338CA); // Indigo 700
  static const Color secondary = Color(0xFF14B8A6); // Teal 500
  static const Color secondaryVariant = Color(0xFF0F766E); // Teal 700
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF1E293B); // Slate 800
  static const Color onSurface = Color(0xFF1E293B); // Slate 800
  static const Color onError = Colors.white;

  // Dark Theme Colors (Deep Slate)
  static const Color darkPrimary = Color(0xFF818CF8); // Indigo 400
  static const Color darkPrimaryVariant = Color(0xFF3730A3); // Indigo 800
  static const Color darkSecondary = Color(0xFF2DD4BF); // Teal 400
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkError = Color(0xFFF87171); // Red 400
  static const Color darkOnPrimary = Colors.white;
  static const Color darkOnSecondary = Color(0xFF0F172A); // Slate 900
  static const Color darkOnBackground = Color(0xFFF1F5F9); // Slate 100
  static const Color darkOnSurface = Color(0xFFF8FAFC); // Slate 50
  static const Color darkOnError = Color(0xFF0F172A);
  
  // Modern Theme Colors (Dashboard Revamp)
  static const Color modernPrimary = Color(0xFF3B82F6); // Bright Blue
  static const Color modernSecondary = Color(0xFF60A5FA); // Lighter Blue
  static const Color sidebarBackground = Color(0xFF2563EB); // Deep Blue Sidebar
  static const Color dashboardBackground = Color(0xFFF1F5F9); // Light Grayish Blue
  static const Color cardBackground = Colors.white;
  static const Color headerBackground = Colors.white;
  static const Color sidebarItemActive = Colors.white24;
  static const Color sidebarTextActive = Colors.white;
  static const Color sidebarTextInactive = Colors.white70;

}

class AppConstants {
  static const List<String> schoolClasses = [
    'NUR', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
  ];
  static const String youtubeApiKey = 'AIzaSyDrEPFqGTCHyzaSL6E5VfPrKZCQaaTj6DE'; // Provided by user
  static const String googleMapsApiKey = 'AIzaSyA1_wa2YHD_NA3ImtlBmhwLiAQmnRoygV8'; // From AndroidManifest
}

class AppStrings {
  static const String appName = 'Veena Public School';
  static const String schoolAddress = 'KHIDDI, RAJOUN, BANKA (BIHAR) - 813107'; 
  static const String schoolPhone = '+91 91550 56860'; // Typical for this school, but keeping user provided if any
  static const String schoolEmail = 'veenapublicschool@gmail.com'; // More typical than .com domain
  static const String aiAgentName = 'Veena AI Assist';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String student = 'Student';
  static const String teacher = 'Teacher';
  static const String principal = 'Principal';
  static const String admin = 'Admin';
  static const String pending = 'Pending';
}
