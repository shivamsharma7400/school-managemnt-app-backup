
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vps/features/common/routine_view_screen.dart';
import 'package:vps/features/principal/routine_management_screen.dart';
import 'package:vps/data/services/routine_service.dart';
import 'package:vps/data/services/auth_service.dart';
import 'package:mockito/mockito.dart';

class MockRoutineService extends Mock implements RoutineService {
  @override
  Stream<List<Map<String, dynamic>>> getRoutines(String? type) => Stream.value([]);
}

class MockAuthService extends Mock implements AuthService {
  @override
  String get role => 'principal';
}

void main() {
  testWidgets('RoutineViewScreen contains Time Table tab', (WidgetTester tester) async {
    final mockRoutineService = MockRoutineService();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<RoutineService>.value(
          value: mockRoutineService,
          child: RoutineViewScreen(),
        ),
      ),
    );

    expect(find.text('Time Table'), findsOneWidget);
    expect(find.byIcon(Icons.table_chart), findsWidgets);
  });

  testWidgets('RoutineManagementScreen contains Time Table tab', (WidgetTester tester) async {
    final mockRoutineService = MockRoutineService();
    final mockAuthService = MockAuthService();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<RoutineService>.value(value: mockRoutineService),
            ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ],
          child: RoutineManagementScreen(),
        ),
      ),
    );

    expect(find.text('Time Table'), findsOneWidget);
  });
}
