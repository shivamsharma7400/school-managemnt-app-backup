import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';

class ExamRoutineScreen extends StatefulWidget {
  final ScheduledExam exam;

  const ExamRoutineScreen({super.key, required this.exam});

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
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Exam Routine', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: _isRoutineCreated ? _buildRoutineContent() : _buildWizardContent(),
              ),
            ],
          ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _isRoutineCreated ? 'Exam Routine' : 'Create Routine',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                bottom: -20,
                child: Icon(Icons.event_note, size: 200, color: Colors.white.withOpacity(0.05)),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.exam.name,
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${DateFormat('dd MMM').format(widget.exam.startDate)} - ${DateFormat('dd MMM yyyy').format(widget.exam.endDate)}',
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: _isRoutineCreated
          ? [
              IconButton(
                icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit, color: _isEditMode ? Colors.greenAccent : Colors.white),
                onPressed: () => setState(() => _isEditMode = !_isEditMode),
              ),
              if (_isEditMode)
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.blueAccent),
                  onPressed: _saveRoutine,
                ),
              const SizedBox(width: 8),
            ]
          : null,
    );
  }

  Widget _buildWizardContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildWizardHeader(),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStepView(),
          ),
          const SizedBox(height: 48),
          _buildWizardNavigation(),
        ],
      ),
    );
  }

  Widget _buildWizardHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            bool isCompleted = _currentStep > index;
            bool isActive = _currentStep == index;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : (isActive ? const Color(0xFF4F46E5) : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(color: isActive ? const Color(0xFF4F46E5) : Colors.grey.shade300),
                      boxShadow: isActive ? [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (index < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? Colors.green : Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subjects', style: GoogleFonts.inter(fontSize: 10, fontWeight: _currentStep == 0 ? FontWeight.bold : FontWeight.normal)),
            Text('Sittings', style: GoogleFonts.inter(fontSize: 10, fontWeight: _currentStep == 1 ? FontWeight.bold : FontWeight.normal)),
            Text('Duration', style: GoogleFonts.inter(fontSize: 10, fontWeight: _currentStep == 2 ? FontWeight.bold : FontWeight.normal)),
            Text('Time', style: GoogleFonts.inter(fontSize: 10, fontWeight: _currentStep == 3 ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildSubjectStep();
      case 1:
        return _buildSittingsStep();
      case 2:
        return _buildDurationStep();
      case 3:
        return _buildTimeStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSubjectStep() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step 1: Exam Subjects', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('List all subjects and their total marks for this examination.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _subjectController,
                    decoration: _buildInputDecoration('Subject Name', Icons.book_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _fullMarksController,
                    decoration: _buildInputDecoration('Marks', Icons.numbers),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(16)),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addSubject,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_subjects.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.asMap().entries.map((e) => Chip(
                  backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                  side: BorderSide(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                  label: Text('${e.value['name']} (${e.value['fullMarks']})', style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 12)),
                  onDeleted: () => _removeSubject(e.key),
                  deleteIconColor: const Color(0xFF4F46E5),
                )).toList(),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No subjects added yet', style: GoogleFonts.inter(color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSittingsStep() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step 2: Exam Sittings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('How many exam sessions will be held each day?', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 32),
            Row(
              children: [1, 2, 3].map((s) {
                bool isSelected = _sittings == s;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => setState(() => _sittings = s),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, width: isSelected ? 2 : 1),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_seat, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey),
                            const SizedBox(height: 8),
                            Text('$s Sitting${s > 1 ? 's' : ''}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF4F46E5) : Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationStep() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step 3: Exam Duration', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Set the standard duration for each exam sitting.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 32),
            TextField(
              decoration: _buildInputDecoration('e.g. 2.5 Hours', Icons.timer_outlined),
              onChanged: (val) => _examDuration = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStep() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step 4: Timing', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Specify when the first sitting starts and ends.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerCard('Start Time', _startTime, true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePickerCard('End Time', _endTime, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerCard(String label, TimeOfDay time, bool isStart) {
    return InkWell(
      onTap: () => _selectTime(context, isStart),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Text(time.format(context), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton.icon(
            onPressed: () => setState(() => _currentStep -= 1),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          )
        else
          const SizedBox(),
        ElevatedButton.icon(
          onPressed: () {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            } else {
              _initializeRoutineAssignments();
              setState(() => _isRoutineCreated = true);
              _saveRoutine();
            }
          },
          icon: Icon(_currentStep < 3 ? Icons.arrow_forward : Icons.check_circle),
          label: Text(_currentStep < 3 ? 'Continue' : 'Generate Routine'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildRoutineLegend(),
          const SizedBox(height: 24),
          if (_isEditMode) _buildDraggableSubjects(),
          _buildModernRoutineTable(),
          const SizedBox(height: 48),
          _buildRoutineControls(),
        ],
      ),
    );
  }

  Widget _buildRoutineLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$_examDuration per sitting', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 24),
          const Icon(Icons.schedule, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('${_startTime.format(context)} - ${_endTime.format(context)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildModernRoutineTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columnSpacing: 40,
            horizontalMargin: 24,
            columns: [
              DataColumn(label: Text('DATE & DAY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF64748B)))),
              ...List.generate(_sittings, (index) => DataColumn(
                label: Text('SITTING ${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF64748B))),
              )),
            ],
            rows: _days.map((day) {
              final assignments = _routineAssignments[day] ?? List.generate(_sittings, (_) => null);
              bool isToday = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(DateTime.now());
              
              return DataRow(
                color: isToday ? WidgetStateProperty.all(const Color(0xFF4F46E5).withOpacity(0.02)) : null,
                cells: [
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM').format(day), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(DateFormat('EEEE').format(day), style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey.shade400)),
                      ],
                    ),
                  ),
                  ...List.generate(_sittings, (sittingIndex) {
                    final subject = assignments[sittingIndex];
                    return DataCell(
                      _isEditMode
                          ? DragTarget<String>(
                              onAcceptWithDetails: (details) {
                                setState(() {
                                  _routineAssignments[day]![sittingIndex] = details.data;
                                });
                              },
                              builder: (context, candidateData, rejectedData) {
                                return _buildTableCell(subject, isGhost: candidateData.isNotEmpty);
                              },
                            )
                          : _buildTableCell(subject),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String? subject, {bool isGhost = false}) {
    bool isHoliday = subject == null;
    return Container(
      width: 140,
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isGhost ? Colors.green.withOpacity(0.1) : (isHoliday ? const Color(0xFFF8FAFC) : const Color(0xFF4F46E5).withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isGhost ? Colors.green.withOpacity(0.3) : (isHoliday ? Colors.grey.shade100 : const Color(0xFF4F46E5).withOpacity(0.2))),
      ),
      alignment: Alignment.center,
      child: Text(
        subject ?? 'Prep Leave',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isHoliday ? FontWeight.normal : FontWeight.bold,
          color: isHoliday ? Colors.grey : const Color(0xFF4F46E5),
          fontStyle: isHoliday ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildRoutineControls() {
    return Column(
      children: [
        if (_isEditMode)
          Text('Long press and drag items from the list above onto the table to assign them.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _isRoutineCreated = false;
            _isEditMode = false;
            _currentStep = 0;
          }),
          icon: const Icon(Icons.refresh),
          label: const Text('Reset Component Structure'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.redAccent.withOpacity(0.2))),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableSubjects() {
    return Column(
      children: [
        Text(
          'Drag Subjects to the Table',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5)),
        ),
        const SizedBox(height: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(display, style: const TextStyle(color: Colors.white)),
                ),
              ),
              childWhenDragging: Chip(
                label: Text(display, style: const TextStyle(color: Colors.grey)),
                backgroundColor: Colors.grey[200],
              ),
              child: Chip(
                label: Text(display, style: const TextStyle(color: Colors.white)),
                backgroundColor: const Color(0xFF4F46E5),
                avatar: const Icon(Icons.drag_indicator, size: 16, color: Colors.white70),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
