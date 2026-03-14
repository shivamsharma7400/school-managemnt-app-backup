
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'core/constants/app_constants.dart';
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
import 'data/services/complaint_service.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/student/student_dashboard.dart';
import 'features/teacher/teacher_dashboard.dart';
import 'features/principal/principal_dashboard.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/management/management_dashboard.dart';
import 'features/driver/driver_dashboard.dart';
import 'features/auth/pending_approval_screen.dart';
import 'features/student/passed_out_dashboard.dart';
import 'features/staff/staff_dashboard.dart';
import 'features/admin/developer_dashboard.dart';
import 'features/common/splash_screen.dart';

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
  const MyApp({super.key});

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
        ChangeNotifierProvider(create: (_) => AssignmentService()),
        ChangeNotifierProvider(create: (_) => LeaveService()),
        ChangeNotifierProvider(create: (_) => TestService()),
        ChangeNotifierProvider(create: (_) => OnlineClassService()),
        ChangeNotifierProvider(create: (_) => AIService()),
        ChangeNotifierProvider(create: (_) => SchoolInfoService()),
        ChangeNotifierProvider(create: (_) => StudentQueryService()),
        ChangeNotifierProvider(create: (_) => BusService()),
        ChangeNotifierProvider(create: (_) => NotificationService()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
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
            home: const SplashScreen(), // Premium Splash Screen as initial entry
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
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authService.user == null && !authService.isDeveloperLoggedIn) {
      return const LoginScreen();
    }

    // Role based routing
    switch (authService.role) {
      case 'student':
        return const StudentDashboard();
      case 'teacher':
        return const TeacherDashboard();
      case 'principal':
        return const PrincipalDashboard();
      case 'management':
        return const ManagementDashboard();
      case 'admin':
        return const AdminDashboard();
      case 'driver':
        return const DriverDashboard();
      case 'passed_out':
        return const PassedOutDashboard();
      case 'staff':
        return const StaffDashboard();
      case 'developer':
        return const DeveloperDashboard();
      case 'pending':
        return const PendingApprovalScreen();
      default:
        return const PendingApprovalScreen();
    }
  }
}
