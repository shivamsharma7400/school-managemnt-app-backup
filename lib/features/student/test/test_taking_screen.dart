import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
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
      debugPrint("Could not enable secure mode: $e");
    }
  }

  Future<void> _disableSecureMode() async {
    try {
      await ScreenProtector.protectDataLeakageOff();
    } catch (e) {
      debugPrint("Could not disable secure mode: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _submitTest(autoSubmit: true);
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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

    setState(() => _isSubmitting = true);
    _timer.cancel();

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
      id: const Uuid().v4(),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(
                  autoSubmit ? Icons.warning_rounded : Icons.check_circle_rounded,
                  color: autoSubmit ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 12),
                Text(
                  autoSubmit ? "Auto-Submitted" : "Test Completed",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reason != null) 
                  Text(
                    "Reason: $reason",
                    style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text("Your Score", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey)),
                      Text(
                        "$score / ${widget.test.questions.length}",
                        style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                   Navigator.pop(context); // Close dialog
                   Navigator.pop(context); // Close screen
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Done', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    String timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.test.title,
            style: GoogleFonts.poppins(color: Colors.blueGrey[800], fontWeight: FontWeight.bold, fontSize: 18),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _remainingSeconds < 60 ? Colors.red[50] : Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: _remainingSeconds < 60 ? Colors.red : Colors.blueGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds < 60 ? Colors.red : Colors.blueGrey[800],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: widget.test.questions.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.test.questions.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitTest(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(
                    'FINISH & SUBMIT',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              );
            }

            final q = widget.test.questions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueGrey[50]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${index + 1}.",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q.text,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey[800]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (q.type == 'mcq') ...[
                    ...q.options.map((opt) {
                      bool isSelected = _answers[q.id] == opt;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blueAccent.withOpacity(0.05) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.blueGrey[100]!),
                        ),
                        child: RadioListTile<String>(
                          title: Text(opt, style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[700])),
                          value: opt,
                          groupValue: _answers[q.id],
                          activeColor: Colors.blueAccent,
                          onChanged: (val) => setState(() => _answers[q.id] = val!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }).toList(),
                  ] else ...[
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[300]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueGrey[100]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueGrey[100]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
                        filled: true,
                        fillColor: Colors.blueGrey[50]?.withOpacity(0.3),
                      ),
                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.blueGrey[800]),
                      onChanged: (val) => _answers[q.id] = val,
                    ),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
