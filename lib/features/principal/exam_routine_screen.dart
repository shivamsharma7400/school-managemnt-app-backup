import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';

class ExamRoutineScreen extends StatefulWidget {
  final ScheduledExam exam;

  const ExamRoutineScreen({Key? key, required this.exam}) : super(key: key);

  @override
  _ExamRoutineScreenState createState() => _ExamRoutineScreenState();
}

class _ExamRoutineScreenState extends State<ExamRoutineScreen> {
  int _currentStep = 0;
  bool _isRoutineCreated = false;
  bool _isEditMode = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // Data for creation
  List<Map<String, dynamic>> _subjects = [];
  late TextEditingController _subjectController;
  late TextEditingController _fullMarksController;
  int _sittings = 1;
  String _examDuration = '2.5 Hours';
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 11, minute: 30);

  // Table Data
  List<DateTime> _days = [];
  Map<DateTime, List<String?>> _routineAssignments = {};

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _fullMarksController = TextEditingController(text: '100');
    _calculateDays();
    _loadRoutine();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _fullMarksController.dispose();
    super.dispose();
  }

  void _calculateDays() {
    _days = [];
    DateTime current = widget.exam.startDate;
    while (current.isBefore(widget.exam.endDate) || 
           current.isAtSameMomentAs(widget.exam.endDate)) {
      _days.add(current);
      current = current.add(Duration(days: 1));
    }
  }

  Future<void> _loadRoutine() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .get();

      if (doc.exists && doc.data()!.containsKey('routine_config')) {
        final data = doc.data()!;
        final config = data['routine_config'] as Map<String, dynamic>;
        final assignments = data['routine_assignments'] as Map<String, dynamic>? ?? {};

        setState(() {
          // Backward compatibility: check if subjects is list of strings or list of maps
          final rawSubjects = config['subjects'] ?? [];
          _subjects = (rawSubjects as List).map((s) {
            if (s is String) {
              return {'name': s, 'fullMarks': 100.0};
            }
            return Map<String, dynamic>.from(s);
          }).toList();

          _sittings = config['sittings'] ?? 1;
          _examDuration = config['duration'] ?? '2.5 Hours';
          
          final startStr = config['startTime'] ?? '09:00';
          _startTime = TimeOfDay(
            hour: int.parse(startStr.split(':')[0]),
            minute: int.parse(startStr.split(':')[1]),
          );

          final endStr = config['endTime'] ?? '11:30';
          _endTime = TimeOfDay(
            hour: int.parse(endStr.split(':')[0]),
            minute: int.parse(endStr.split(':')[1]),
          );

          // Restore assignments
          _routineAssignments = {};
          for (var day in _days) {
            String dateKey = DateFormat('yyyy-MM-dd').format(day);
            if (assignments.containsKey(dateKey)) {
              _routineAssignments[day] = List<String?>.from(assignments[dateKey]);
            } else {
              _routineAssignments[day] = List.generate(_sittings, (_) => null);
            }
          }

          _isRoutineCreated = true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading routine: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRoutine() async {
    setState(() => _isSaving = true);
    try {
      // Serialize assignments: Map<DateTime, List<String?>> -> Map<String, List<String?>>
      final serializedAssignments = <String, dynamic>{};
      _routineAssignments.forEach((key, value) {
        serializedAssignments[DateFormat('yyyy-MM-dd').format(key)] = value;
      });

      final routineConfig = {
        'subjects': _subjects,
        'sittings': _sittings,
        'duration': _examDuration,
        'startTime': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'endTime': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      };

      await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .update({
            'routine_config': routineConfig,
            'routine_assignments': serializedAssignments,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Routine saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving routine: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _initializeRoutineAssignments() {
    _routineAssignments = {
      for (var day in _days) day: List.generate(_sittings, (_) => null)
    };
  }

  void _addSubject() {
    if (_subjectController.text.isNotEmpty && _fullMarksController.text.isNotEmpty) {
      setState(() {
        _subjects.add({
          'name': _subjectController.text.trim(),
          'fullMarks': double.tryParse(_fullMarksController.text) ?? 100.0,
        });
        _subjectController.clear();
        _fullMarksController.text = '100';
      });
    }
  }

  void _removeSubject(int index) {
    setState(() {
      _subjects.removeAt(index);
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  Widget _buildCreationWizard() {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(primary: AppColors.modernPrimary),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 3) {
                setState(() => _currentStep += 1);
              } else {
                _initializeRoutineAssignments();
                setState(() => _isRoutineCreated = true);
                _saveRoutine(); // Save initial config
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            steps: [
              Step(
                title: Text('Add Subjects & Marks', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _subjectController,
                            decoration: InputDecoration(hintText: 'Subject Name (e.g. Math)'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _fullMarksController,
                            decoration: InputDecoration(hintText: 'Full Marks'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: AppColors.modernPrimary), 
                          onPressed: () => _addSubject(),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subjects.asMap().entries.map((e) => Chip(
                        label: Text('${e.value['name']} (${e.value['fullMarks']})'),
                        onDeleted: () => _removeSubject(e.key),
                      )).toList(),
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: Text('Number of Sittings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: DropdownButton<int>(
                  value: _sittings,
                  isExpanded: true,
                  items: [1, 2, 3].map((s) => DropdownMenuItem(value: s, child: Text('$s Sitting(s)'))).toList(),
                  onChanged: (val) => setState(() => _sittings = val!),
                ),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: Text('Exam Duration', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: TextField(
                  decoration: InputDecoration(hintText: 'e.g., 2.5 Hours'),
                  onChanged: (val) => _examDuration = val,
                ),
                isActive: _currentStep >= 2,
              ),
              Step(
                title: Text('Start & End Time', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text('Start: ${_startTime.format(context)}'),
                        onTap: () => _selectTime(context, true),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('End: ${_endTime.format(context)}'),
                        onTap: () => _selectTime(context, false),
                      ),
                    ),
                  ],
                ),
                isActive: _currentStep >= 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineTable() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.modernPrimary.withOpacity(0.1)),
          border: TableBorder.all(color: Colors.grey[300]!),
          columns: [
            DataColumn(label: Text('Date', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
            ...List.generate(_sittings, (index) => DataColumn(
              label: Text('Sitting ${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            )),
          ],
          rows: _days.map((day) {
            final assignments = _routineAssignments[day] ?? List.generate(_sittings, (_) => null);
            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd MMM (EEE)').format(day))),
                ...List.generate(_sittings, (sittingIndex) {
                  final subject = assignments[sittingIndex];
                  return DataCell(
                    _isEditMode
                        ? DragTarget<String>(
                            onAccept: (data) {
                              setState(() {
                                _routineAssignments[day]![sittingIndex] = data;
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                width: 120,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: candidateData.isNotEmpty ? Colors.green.withOpacity(0.1) : null,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  subject ?? 'Study Leave',
                                  style: TextStyle(
                                    color: subject == null ? Colors.grey : Colors.black,
                                    fontStyle: subject == null ? FontStyle.italic : FontStyle.normal,
                                  ),
                                ),
                              );
                            },
                          )
                        : Text(
                            subject ?? 'Study Leave',
                            style: TextStyle(
                              color: subject == null ? Colors.grey : Colors.black,
                              fontStyle: subject == null ? FontStyle.italic : FontStyle.normal,
                              fontWeight: subject != null ? FontWeight.w500 : null,
                            ),
                          ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDraggableSubjects() {
    return Column(
      children: [
        Text(
          'Drag Subjects to the Table',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.modernPrimary),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _subjects.map((subjectData) {
            final String subject = subjectData['name'];
            final String display = '$subject (${subjectData['fullMarks']})';
            return Draggable<String>(
              data: subject,
              feedback: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.modernPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(display, style: TextStyle(color: Colors.white)),
                ),
              ),
              childWhenDragging: Chip(
                label: Text(display, style: TextStyle(color: Colors.grey)),
                backgroundColor: Colors.grey[200],
              ),
              child: Chip(
                label: Text(display, style: TextStyle(color: Colors.white)),
                backgroundColor: AppColors.modernPrimary,
                avatar: Icon(Icons.drag_indicator, size: 16, color: Colors.white70),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Exam Routine')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('Exam Routine', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: _isRoutineCreated ? [
          if (_isEditMode)
            IconButton(
              icon: Icon(Icons.save, color: AppColors.modernPrimary),
              onPressed: _saveRoutine,
              tooltip: 'Save Routine',
            ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit),
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
            tooltip: _isEditMode ? 'Finish Editing' : 'Edit Routine',
          ),
          SizedBox(width: 8),
        ] : null,
      ),
      body: Stack(
        children: [
          _isRoutineCreated 
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Generated Routine for ${widget.exam.name}',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Duration: $_examDuration | Time: ${_startTime.format(context)} - ${_endTime.format(context)}',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    if (_isEditMode) _buildDraggableSubjects(),
                    _buildRoutineTable(),
                    SizedBox(height: 48),
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => setState(() {
                          _isRoutineCreated = false;
                          _isEditMode = false;
                        }),
                        child: Text('Reset / Re-create Routine'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Create Routine for ${widget.exam.name}',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(child: _buildCreationCreationWizard()),
                ],
              ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // Renamed to avoid confusion with the method I'm replacing if any
  Widget _buildCreationCreationWizard() => _buildCreationWizard();
}
