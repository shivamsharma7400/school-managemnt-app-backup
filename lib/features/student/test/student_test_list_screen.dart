import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/test_model.dart';
import '../../../data/services/test_service.dart';
import '../../../data/services/auth_service.dart';
import 'test_taking_screen.dart';

class StudentTestListScreen extends StatelessWidget {
  const StudentTestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final testService = Provider.of<TestService>(context);
    final userClassId = authService.classId;

    if (userClassId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text("No Class Assigned", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Please contact administration", style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          StreamBuilder<List<Test>>(
            stream: testService.getTestsForClass(userClassId),
            builder: (context, testSnapshot) {
              if (testSnapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (testSnapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Error: ${testSnapshot.error}')));
              }
              if (!testSnapshot.hasData || testSnapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No tests available yet', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }

              final tests = testSnapshot.data!;
              
              // Group tests by teacher name
              final Map<String, List<Test>> groupedTests = {};
              for (var test in tests) {
                final teacherName = test.createdByName;
                groupedTests.putIfAbsent(teacherName, () => []).add(test);
              }

              return StreamBuilder<List<String>>(
                stream: testService.getCompletedTestIds(authService.user!.uid),
                builder: (context, resultSnapshot) {
                  final completedIds = resultSnapshot.data ?? [];
                  final teacherNames = groupedTests.keys.toList()..sort((a, b) {
                    if (a == 'Unorganized') return 1;
                    if (b == 'Unorganized') return -1;
                    return a.compareTo(b);
                  });

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final teacherName = teacherNames[index];
                          final teacherTests = groupedTests[teacherName]!;
                          
                          return _buildTeacherFolder(context, teacherName, teacherTests, completedIds);
                        },
                        childCount: teacherNames.length,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'Online Tests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo[700]!, Colors.indigo[500]!],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.quiz, size: 160, color: Colors.white.withOpacity(0.1)),
              ),
              Positioned(
                bottom: 40,
                left: 16,
                child: Text(
                  "Organized by Teacher",
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherFolder(BuildContext context, String teacherName, List<Test> tests, List<String> completedIds) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.folder_shared_rounded, color: Colors.indigo[600]),
          ),
          title: Text(
            teacherName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blueGrey[900],
            ),
          ),
          subtitle: Text(
            "${tests.length} Released Tests",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          children: tests.map((test) {
            final isCompleted = completedIds.contains(test.id);
            return _buildTestCard(context, test, isCompleted);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, Test test, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted ? null : () => _checkAndStartTest(context, test),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isCompleted ? Colors.green : Colors.deepOrange).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.quiz,
                    color: isCompleted ? Colors.green : Colors.deepOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${test.subject} • ${test.durationMinutes} mins",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.blueGrey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Completed',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _checkAndStartTest(context, test),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Start', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkAndStartTest(BuildContext context, Test test) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final testService = Provider.of<TestService>(context, listen: false);
    
    bool confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Start Test?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("You are about to start '${test.title}'.", style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            _buildRuleRow(Icons.app_blocking, "Do not switch apps"),
            _buildRuleRow(Icons.screen_lock_portrait, "Do not minimize"),
            _buildRuleRow(Icons.no_photography, "Screenshots are disabled"),
            const SizedBox(height: 8),
            Text("Violation will auto-submit the test.", style: GoogleFonts.poppins(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Start Now', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    ) ?? false;

    if (confirm) {
        final taken = await testService.hasStudentTakenTest(test.id, authService.user!.uid);
        if (taken) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('You have already taken this test.', style: GoogleFonts.poppins()),
               backgroundColor: Colors.red,
             )
           );
           return;
        }

        Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => TestTakingScreen(test: test))
        );
    }
  }

  Widget _buildRuleRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueGrey[600])),
        ],
      ),
    );
  }
}
