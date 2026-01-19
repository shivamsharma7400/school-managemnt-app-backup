import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/test_model.dart';
import '../../../data/models/test_result_model.dart';
import '../../../data/services/test_service.dart';
import '../../../data/services/auth_service.dart';

class TestTakingScreen extends StatefulWidget {
  final Test test;

  const TestTakingScreen({Key? key, required this.test}) : super(key: key);

  @override
  _TestTakingScreenState createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> with WidgetsBindingObserver {
  late Timer _timer;
  int _remainingSeconds = 0;
  Map<String, String> _answers = {}; // questionId -> answer
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecureMode();
    _remainingSeconds = widget.test.durationMinutes * 60;
    _startTimer();
  }

  Future<void> _enableSecureMode() async {
    try {
      await ScreenProtector.protectDataLeakageOn();
    } catch (e) {
      print("Could not enable secure mode: $e");
    }
  }

  Future<void> _disableSecureMode() async {
    try {
      await ScreenProtector.protectDataLeakageOff();
    } catch (e) {
      print("Could not disable secure mode: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _submitTest(autoSubmit: true);
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // User left the app or minimized it
      if (!_isSubmitting) {
        _submitTest(autoSubmit: true, reason: "App switched/minimized");
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _disableSecureMode();
    super.dispose();
  }

  void _submitTest({bool autoSubmit = false, String? reason}) async {
    if (_isSubmitting) return;

    _isSubmitting = true;
    _timer.cancel();

    // Calculate Score
    int score = 0;
    for (var q in widget.test.questions) {
      String? userAns = _answers[q.id]?.trim();
      String correctAns = q.correctAnswer.trim();
      
      if (userAns == correctAns) {
        score++;
      }
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final testService = Provider.of<TestService>(context, listen: false);

    final result = TestResult(
      id: Uuid().v4(),
      testId: widget.test.id,
      testTitle: widget.test.title,
      studentId: authService.user!.uid,
      studentName: authService.userName,
      score: score,
      totalQuestions: widget.test.questions.length,
      submittedAt: DateTime.now(),
    );

    await testService.submitTestResult(result);

    if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(autoSubmit ? "Test Auto-Submitted" : "Test Submitted"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reason != null) Text("Reason: $reason\n", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                Text("Your Score: $score / ${widget.test.questions.length}"),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                   Navigator.pop(context); // Close dialog
                   Navigator.pop(context); // Close screen
                }, 
                child: Text('Close')
              ),
            ],
          )
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format Time
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    String timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button
        return false; 
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.test.title),
          automaticallyImplyLeading: false, // Hide back button
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  timeStr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _remainingSeconds < 60 ? Colors.red : Colors.white),
                ),
              ),
            )
          ],
        ),
        body: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: widget.test.questions.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.test.questions.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: ElevatedButton(
                  onPressed: () => _submitTest(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: Text('SUBMIT TEST', style: TextStyle(fontSize: 18)),
                ),
              );
            }

            final q = widget.test.questions[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Q${index+1}. ${q.text}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    SizedBox(height: 12),
                    if (q.type == 'mcq') ...[
                      ...q.options.map((opt) => RadioListTile<String>(
                        title: Text(opt),
                        value: opt,
                        groupValue: _answers[q.id],
                        onChanged: (val) => setState(() => _answers[q.id] = val!),
                      )).toList(),
                    ] else ...[
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your answer',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => _answers[q.id] = val,
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
