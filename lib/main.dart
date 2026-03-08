
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'core/constants/app_constants.dart';
// import 'data/services/mock_auth_service.dart'; // Switch to mock
import 'data/services/auth_service.dart';
import 'data/services/attendance_service.dart';
import 'data/services/fee_service.dart';
import 'data/services/user_service.dart';
import 'data/services/routine_service.dart';
import 'data/services/announcement_service.dart';
import 'data/services/result_service.dart';
import 'data/services/class_service.dart';
import 'data/services/assignment_service.dart';
import 'data/services/leave_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/test_service.dart';
import 'data/services/online_class_service.dart';
import 'data/services/ai_service.dart';
import 'data/services/school_info_service.dart';
import 'data/services/student_query_service.dart';
import 'data/services/strategic_planning_service.dart';

import 'data/services/bus_service.dart';
import 'data/services/bus_routine_service.dart';
import 'data/services/school_config_service.dart';
import 'data/services/complaint_service.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/student/student_dashboard.dart'; // Placeholder
import 'features/teacher/teacher_dashboard.dart'; // Placeholder
import 'features/principal/principal_dashboard.dart'; // Placeholder
import 'features/admin/admin_dashboard.dart';
import 'features/management/management_dashboard.dart';
import 'features/driver/driver_dashboard.dart';
import 'features/auth/pending_approval_screen.dart';
import 'features/student/passed_out_dashboard.dart';
import 'features/common/splash_screen.dart';
import 'features/staff/staff_dashboard.dart';
import 'features/admin/developer_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
        ChangeNotifierProvider(create: (_) => FeeService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => RoutineService()),
        ChangeNotifierProvider(create: (_) => AnnouncementService()),
        ChangeNotifierProvider(create: (_) => ResultService()),
        ChangeNotifierProvider(create: (_) => ClassService()),
        // Removed duplicate ClassService
        ChangeNotifierProvider(create: (_) => AssignmentService()),
        ChangeNotifierProvider(create: (_) => LeaveService()),
        ChangeNotifierProvider(create: (_) => TestService()),
        ChangeNotifierProvider(create: (_) => OnlineClassService()), // Added
        ChangeNotifierProvider(create: (_) => AIService()),
        ChangeNotifierProvider(create: (_) => SchoolInfoService()),
        ChangeNotifierProvider(create: (_) => StudentQueryService()),
        ChangeNotifierProvider(create: (_) => BusService()),
        ChangeNotifierProvider(create: (_) => NotificationService()..initialize()), // Init here

        ChangeNotifierProvider(create: (_) => SchoolConfigService()),
        ChangeNotifierProvider(create: (_) => ThemeService()), // Add ThemeService
        Provider(create: (_) => ComplaintService()),
        ChangeNotifierProvider(create: (_) => StrategicPlanningService()),
        ChangeNotifierProvider(create: (_) => BusRoutineService()),
      ],
      child: Consumer2<ThemeService, AuthService>(
        builder: (context, themeService, authService, child) {
          final isModern = authService.role == 'principal' || authService.role == 'management' || authService.role == 'admin';
          
          return GetMaterialApp(
            title: AppStrings.appName,
            theme: isModern ? AppTheme.modernTheme : AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            home: AuthWrapper(), // Changed from SplashScreen to AuthWrapper for better flow control
            routes: {
              '/register': (context) => RegisterScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authService.user == null && !authService.isDeveloperLoggedIn) {
      return LoginScreen();
    }

    // Role based routing
    switch (authService.role) {
      case 'student':
        return StudentDashboard();
      case 'teacher':
        return TeacherDashboard();
      case 'principal':
        return PrincipalDashboard();
      case 'management':
        return ManagementDashboard();
      case 'admin':
        return AdminDashboard();
      case 'driver':
        return DriverDashboard();
      case 'passed_out':
        return PassedOutDashboard();
      case 'staff':
        return StaffDashboard();
      case 'developer':
        return DeveloperDashboard();
      case 'pending':
        return PendingApprovalScreen();
      default:
        // If role fetch failed or default
        return PendingApprovalScreen();
    }
  }
}


