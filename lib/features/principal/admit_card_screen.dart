import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/scheduled_exam_model.dart';
import '../../data/models/class_model.dart';
import '../../data/services/class_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/student_exam_pdf_service.dart';

class AdmitCardScreen extends StatefulWidget {
  final ScheduledExam exam;

  const AdmitCardScreen({super.key, required this.exam});

  @override
  _AdmitCardScreenState createState() => _AdmitCardScreenState();
}

class _AdmitCardScreenState extends State<AdmitCardScreen> with TickerProviderStateMixin {
  bool _isIssuedClicked = false;
  TabController? _tabController;
  List<ClassModel> _classes = [];
  Map<String, dynamic>? _routineConfig;
  Map<String, dynamic>? _routineAssignments;
  bool _isLoadingRoutine = false;

  @override
  void initState() {
    super.initState();
    _fetchRoutineData();
  }

  Future<void> _fetchRoutineData() async {
    setState(() => _isLoadingRoutine = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('scheduled_exams')
          .doc(widget.exam.id)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _routineConfig = data['routine_config'];
          _routineAssignments = data['routine_assignments'];
        });
      }
    } catch (e) {
      print('Error fetching routine for admit card: $e');
    } finally {
      setState(() => _isLoadingRoutine = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(int count) {
    if (_tabController == null || _tabController!.length != count) {
      _tabController?.dispose();
      _tabController = TabController(length: count, vsync: this);
    }
  }

  Future<void> _printAdmitCard(Map<String, dynamic> student) async {
    await StudentExamPdfService.printAdmitCard(widget.exam, student, _routineConfig, _routineAssignments);
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.modernPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.badge, size: 80, color: AppColors.modernPrimary),
          ),
          SizedBox(height: 32),
          Text(
            'Issue Admit Cards',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Click below to generate admit cards for students\nwith clear dues only.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          SizedBox(height: 48),
          SizedBox(
            width: 250,
            height: 60,
            child: ElevatedButton(
              onPressed: () => setState(() => _isIssuedClicked = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.modernPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: Text('ISSUE ADMIT CARD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(ClassModel classModel) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context, listen: false).getStudentsByClass(classModel.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data ?? [];
        // Filter students where currentDue is 0 or less
        final eligibleStudents = students.where((s) {
          final double due = (s['currentDue'] as num?)?.toDouble() ?? 0.0;
          return due <= 0;
        }).toList();

        if (eligibleStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text('No students with clear dues in Class ${classModel.name}', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: eligibleStudents.length,
          itemBuilder: (context, index) {
            final student = eligibleStudents[index];
            student['className'] = classModel.name; // For PDF printing
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.modernPrimary.withOpacity(0.1),
                  child: Text(student['name']?[0] ?? 'S', style: TextStyle(color: AppColors.modernPrimary)),
                ),
                title: Text(student['name'] ?? 'Unknown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                subtitle: Text('Adm No: ${student['admNo'] ?? 'N/A'}'),
                trailing: ElevatedButton.icon(
                  onPressed: () => _printAdmitCard(student),
                  icon: Icon(Icons.print, size: 18),
                  label: Text('Print Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.modernPrimary,
                    side: BorderSide(color: AppColors.modernPrimary),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClassModel>>(
      stream: Provider.of<ClassService>(context, listen: false).getAllClasses(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _classes = snapshot.data!;
          _classes.sort((a, b) {
            final indexA = AppConstants.schoolClasses.indexOf(a.name);
            final indexB = AppConstants.schoolClasses.indexOf(b.name);
            if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
            return a.name.compareTo(b.name);
          });
          
          if (_classes.isNotEmpty) {
            _updateTabController(_classes.length);
          }
        }

        final bool isReady = _isIssuedClicked && 
                            _classes.isNotEmpty && 
                            _tabController != null && 
                            _tabController!.length == _classes.length;

        return Scaffold(
          backgroundColor: AppColors.dashboardBackground,
          appBar: AppBar(
            title: Text('Admit Cards', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            bottom: isReady ? TabBar(
              controller: _tabController!,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              tabs: _classes.map((c) => Tab(text: 'Class ${c.name}')).toList(),
            ) : null,
          ),
          body: _isIssuedClicked 
              ? (!isReady || _isLoadingRoutine
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Syncing Routine Data...', style: GoogleFonts.outfit()),
                      ],
                    )) 
                  : TabBarView(
                      controller: _tabController!,
                      children: _classes.map((c) => _buildStudentList(c)).toList(),
                    ))
              : _buildWelcomeView(),
        );
      }
    );
  }
}
