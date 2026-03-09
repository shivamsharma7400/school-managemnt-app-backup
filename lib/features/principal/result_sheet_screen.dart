import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';
import '../../data/models/class_model.dart';
import '../../data/services/class_service.dart';
import '../../data/services/user_service.dart';

class ResultSheetScreen extends StatefulWidget {
  final ScheduledExam exam;

  const ResultSheetScreen({super.key, required this.exam});

  @override
  _ResultSheetScreenState createState() => _ResultSheetScreenState();
}

class _ResultSheetScreenState extends State<ResultSheetScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  List<ClassModel> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Storage for marks: {classId: {studentId: {subject: marks}}}
  final Map<String, Map<String, Map<String, String>>> _marksData = {};
  
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Subjects from Exam Routine
      final examDoc = await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .get();
      
      if (examDoc.exists && examDoc.data()!.containsKey('routine_config')) {
        final config = examDoc.data()!['routine_config'] as Map<String, dynamic>;
        final rawSubjects = config['subjects'] ?? [];
        _subjects = (rawSubjects as List).map((s) {
          if (s is String) {
            return {'name': s, 'fullMarks': 100.0};
          }
          return Map<String, dynamic>.from(s);
        }).toList();
      }

      // 2. Fetch Classes
      _classes = await Provider.of<ClassService>(context, listen: false).fetchAllClasses();
      _classes.sort((a, b) {
        final indexA = AppConstants.schoolClasses.indexOf(a.name);
        final indexB = AppConstants.schoolClasses.indexOf(b.name);
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        return a.name.compareTo(b.name);
      });

      // 3. Initialize Tab Controller
      if (_classes.isNotEmpty) {
        _tabController = TabController(length: _classes.length, vsync: this);
      }

      // 4. Load Existing Results (one-time fetch for all classes or handled per class)
      // For performance, we'll load per class in the build or here.
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .collection('class_results')
          .get();

      for (var doc in resultsSnapshot.docs) {
        _marksData[doc.id] = Map<String, Map<String, String>>.from(
          doc.data().map((key, value) => MapEntry(key, Map<String, String>.from(value)))
        );
      }

    } catch (e) {
      print('Error initializing Result Sheet: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _saveClassResults(String classId) async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .collection('class_results')
          .doc(classId)
          .set(_marksData[classId] ?? {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Results saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving results: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    if (percentage >= 33) return 'P';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        title: Text('Result Sheet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: (_tabController != null && _classes.isNotEmpty) ? TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: _classes.map((c) => Tab(text: 'Class ${c.name}')).toList(),
        ) : null,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _tabController == null 
              ? Center(child: Text('No classes found'))
              : TabBarView(
                  controller: _tabController,
                  children: _classes.map((c) => _buildResultTable(c)).toList(),
                ),
    );
  }

  Widget _buildResultTable(ClassModel classModel) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context, listen: false).getStudentsByClass(classModel.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
        final students = snapshot.data!;
        if (students.isEmpty) {
          return Center(child: Text('No students in Class ${classModel.name}'));
        }

        // Initialize markers for this class if not present
        if (!_marksData.containsKey(classModel.id)) {
          _marksData[classModel.id] = {};
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.modernPrimary),
                          dataRowHeight: 60,
                          horizontalMargin: 20,
                          columns: [
                            _buildHeaderCell('Student Name'),
                            _buildHeaderCell('Adm No.'),
                            ..._subjects.map((s) => _buildHeaderCell(s['name'])),
                            _buildHeaderCell('Total Marks'),
                            _buildHeaderCell('Obtain Marks'),
                            _buildHeaderCell('Score %'),
                            _buildHeaderCell('Grade'),
                          ],
                          rows: students.map((s) {
                            final studentId = s['id'];
                            
                            // Ensure student map exists
                            if (!_marksData[classModel.id]!.containsKey(studentId)) {
                              _marksData[classModel.id]![studentId] = {};
                              for (var sub in _subjects) {
                                _marksData[classModel.id]![studentId]![sub['name']] = '';
                              }
                            }

                            final data = _marksData[classModel.id]![studentId]!;
                            
                            // Calculations
                            double obtained = 0;
                            double autoTotal = 0;
                            for (var sub in _subjects) {
                              final subName = sub['name'];
                              obtained += double.tryParse(data[subName] ?? '0') ?? 0;
                              autoTotal += (sub['fullMarks'] as num?)?.toDouble() ?? 100.0;
                            }
                            
                            double percentage = autoTotal > 0 ? (obtained / autoTotal) * 100 : 0;
                            String grade = _calculateGrade(percentage);

                            return DataRow(cells: [
                              DataCell(Text(s['name'] ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(s['admNo']?.toString() ?? '-')),
                              ..._subjects.map((sub) {
                                final subName = sub['name'];
                                return DataCell(
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: '0'),
                                      onChanged: (val) {
                                        setState(() {
                                          _marksData[classModel.id]![studentId]![subName] = val;
                                        });
                                      },
                                      controller: TextEditingController(text: data[subName])
                                        ..selection = TextSelection.fromPosition(TextPosition(offset: (data[subName] ?? '').length)),
                                    ),
                                  ),
                                );
                              }),
                              DataCell(Text(autoTotal.toStringAsFixed(0))),
                              DataCell(Text(obtained.toStringAsFixed(1), style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                              DataCell(Text('${percentage.toStringAsFixed(1)}%')),
                              DataCell(_buildGradeBadge(grade)),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveClassResults(classModel.id),
                  icon: _isSaving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.save),
                  label: Text('Save Results for Class ${classModel.name}', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.modernPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  DataColumn _buildHeaderCell(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGradeBadge(String grade) {
    Color color;
    switch (grade) {
      case 'A+':
      case 'A': color = Colors.green; break;
      case 'B': color = Colors.blue; break;
      case 'C': color = Colors.orange; break;
      case 'F': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Text(grade, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
