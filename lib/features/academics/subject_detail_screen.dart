import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/auth_service.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String syllabusId;
  final String subjectName;
  final String className;
  final bool isReadOnly;

  const SubjectDetailScreen({
    super.key,
    required this.syllabusId,
    required this.subjectName,
    required this.className,
    this.isReadOnly = false,
  });

  @override
  _SubjectDetailScreenState createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            Text('Class ${widget.className} • Syllabus Hub', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withOpacity(0.8))),
          ],
        ),
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Planning'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SyllabusOverviewTab(
            syllabusId: widget.syllabusId,
            subjectName: widget.subjectName,
            className: widget.className,
            isReadOnly: widget.isReadOnly,
          ),
          _SyllabusPlanningTab(
            syllabusId: widget.syllabusId,
            subjectName: widget.subjectName,
            className: widget.className,
            isReadOnly: widget.isReadOnly,
          ),
        ],
      ),
    );
  }
}

class _SyllabusPlanningTab extends StatefulWidget {
  final String syllabusId;
  final String subjectName;
  final String className;
  final bool isReadOnly;
  const _SyllabusPlanningTab({
    required this.syllabusId,
    required this.subjectName,
    required this.className,
    required this.isReadOnly,
  });

  @override
  State<_SyllabusPlanningTab> createState() => _SyllabusPlanningTabState();
}

class _SyllabusPlanningTabState extends State<_SyllabusPlanningTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateChapterTerm(int index, String? term, List<dynamic> chapters) async {
    List<dynamic> updated = List.from(chapters);
    updated[index]['term'] = term;
    await _firestore.collection('syllabuses').doc(widget.syllabusId).update({
      'chapters': updated,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('syllabuses').doc(widget.syllabusId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null || data['chapters'] == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Initialize syllabus in Overview first', style: GoogleFonts.outfit(color: Colors.grey)),
              ],
            ),
          );
        }

        final List<dynamic> chapters = data['chapters'];
        
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTermSection('First Term', const Color(0xFF6366F1), chapters),
            _buildTermSection('Second Term', const Color(0xFFF59E0B), chapters),
            _buildTermSection('Final Term', const Color(0xFF10B981), chapters),
            const SizedBox(height: 20),
            _buildUnassignedSection(chapters),
          ],
        );
      },
    );
  }

  Widget _buildTermSection(String term, Color color, List<dynamic> allChapters) {
    final termChapters = allChapters.where((c) => c['term'] == term).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(term, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const Spacer(),
            Text('${termChapters.length} Chapters', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(left: 5, top: 10, bottom: 20),
          padding: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color.withOpacity(0.2), width: 2)),
          ),
          child: termChapters.isEmpty
              ? Text('No chapters assigned yet', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic))
              : Column(
                  children: termChapters.map((ch) {
                    final index = allChapters.indexOf(ch);
                    return _buildPlanningChapterCard(ch, index, allChapters, color);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildUnassignedSection(List<dynamic> allChapters) {
    final unassigned = allChapters.where((c) => c['term'] == null).toList();
    if (unassigned.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unassigned Chapters', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: unassigned.map((ch) {
            final index = allChapters.indexOf(ch);
            return ActionChip(
              label: Text(ch['name'], style: GoogleFonts.inter(fontSize: 12)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey[200]!),
              onPressed: () => _showTermSelector(index, allChapters),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlanningChapterCard(Map<String, dynamic> ch, int index, List<dynamic> allChapters, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(ch['name'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20, color: Colors.grey),
              onPressed: () => _showTermSelector(index, allChapters),
            ),
        ],
      ),
    );
  }

  void _showTermSelector(int index, List<dynamic> allChapters) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign to Term', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _termOption('First Term', const Color(0xFF6366F1), index, allChapters),
            _termOption('Second Term', const Color(0xFFF59E0B), index, allChapters),
            _termOption('Final Term', const Color(0xFF10B981), index, allChapters),
            _termOption('Remove Assignment', Colors.grey, index, allChapters, isRemove: true),
          ],
        ),
      ),
    );
  }

  Widget _termOption(String label, Color color, int index, List<dynamic> allChapters, {bool isRemove = false}) {
    return ListTile(
      leading: Icon(isRemove ? Icons.close : Icons.bookmark, color: color),
      title: Text(label, style: GoogleFonts.outfit()),
      onTap: () {
        _updateChapterTerm(index, isRemove ? null : label, allChapters);
        Navigator.pop(context);
      },
    );
  }
}

class _SyllabusOverviewTab extends StatefulWidget {
  final String syllabusId;
  final String subjectName;
  final String className;
  final bool isReadOnly;
  const _SyllabusOverviewTab({
    required this.syllabusId,
    required this.subjectName,
    required this.className,
    required this.isReadOnly,
  });

  @override
  State<_SyllabusOverviewTab> createState() => _SyllabusOverviewTabState();
}

class _SyllabusOverviewTabState extends State<_SyllabusOverviewTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _chapterController = TextEditingController();
  String? _initializedTeacherId;
  String? _initializedTeacherName;

  Future<void> _setChapterCount(int count) async {
    if (_initializedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Subject Teacher first')),
      );
      return;
    }

    List<Map<String, dynamic>> chapters = [];
    for (int i = 1; i <= count; i++) {
      chapters.add({
        'no': i,
        'name': 'Chapter $i: Introduction to Topic $i',
        'status': 'Pending',
      });
    }
    await _firestore.collection('syllabuses').doc(widget.syllabusId).update({
      'chapterCount': count,
      'chapters': chapters,
      'teacherId': _initializedTeacherId,
      'teacherName': _initializedTeacherName,
    });

    // Notify Teacher
    NotificationService().sendNotificationToUser(
      _initializedTeacherId!,
      'New Subject Assigned',
      'You have been assigned as the teacher for ${widget.subjectName} in ${widget.className}.',
    );
  }

  Future<void> _updateTeacher(String id, String name) async {
    await _firestore.collection('syllabuses').doc(widget.syllabusId).update({
      'teacherId': id,
      'teacherName': name,
    });

    // Notify Teacher
    NotificationService().sendNotificationToUser(
      id,
      'Subject Assignment Updated',
      'You are now the assigned teacher for ${widget.subjectName} in ${widget.className}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('syllabuses').doc(widget.syllabusId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (data == null) return const Center(child: Text('Error loading data'));

        final int? chapterCount = data['chapterCount'];
        final List<dynamic>? chapters = data['chapters'];
        final String? assignedTeacherName = data['teacherName'];

        if (chapterCount == null) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 80, color: Color(0xFF6366F1)),
                    const SizedBox(height: 32),
                    Text(
                      'Initialize Syllabus',
                      style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Set the total chapters and assign a subject teacher to begin tracking.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    _buildTeacherDropdown(
                      onChanged: (id, name) => setState(() {
                        _initializedTeacherId = id;
                        _initializedTeacherName = name;
                      }),
                      selectedId: _initializedTeacherId,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _chapterController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                      decoration: InputDecoration(
                        hintText: 'Total Chapters',
                        hintStyle: TextStyle(color: Colors.grey[300], fontSize: 16),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.tag, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          final count = int.tryParse(_chapterController.text);
                          if (count != null && count > 0) {
                            _setChapterCount(count);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid chapter count')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Generate Repository', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Dashboard View
        return Column(
          children: [
            _buildStatsHeader(data),
            _buildTeacherHeader(data['teacherId'], assignedTeacherName),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: chapters!.length,
                itemBuilder: (context, index) {
                  final ch = chapters[index] as Map<String, dynamic>;
                  return _buildChapterCard(index, ch, chapters);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeacherDropdown({required Function(String, String) onChanged, String? selectedId}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final teachers = snapshot.data!.docs;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedId,
              hint: const Text('Select Subject Teacher'),
              items: teachers.map((doc) {
                final name = (doc.data() as Map)['name'] ?? 'Unknown';
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(name, style: GoogleFonts.outfit()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final teacherDoc = teachers.firstWhere((d) => d.id == val);
                  final teacherName = (teacherDoc.data() as Map)['name'] ?? 'Unknown';
                  onChanged(val, teacherName);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherHeader(String? teacherId, String? teacherName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded, color: Colors.indigo),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject Teacher', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text(teacherName ?? 'Not Assigned', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                ],
              ),
            ),
            if (!widget.isReadOnly)
              _buildUpdateTeacherButton(teacherId),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateTeacherButton(String? currentTeacherId) {
    return TextButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Assign Different Teacher'),
            content: _buildTeacherDropdown(
              onChanged: (id, name) {
                _updateTeacher(id, name);
                Navigator.pop(context);
              },
              selectedId: currentTeacherId,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      },
      child: Text('Change', style: GoogleFonts.outfit(color: Colors.indigo, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatsHeader(Map<String, dynamic> data) {
    final progress = (data['progress'] ?? 0.0).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mission Completion', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${(data['chapters'] as List).where((c) => c['status'] == 'Completed').length} / ${data['chapterCount']} Chapters Done',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(int index, Map<String, dynamic> ch, List<dynamic> chapters) {
    final status = ch['status'] ?? 'Pending';
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        statusIcon = Icons.bolt_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          ),
          title: Text(
            ch['name'],
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: status == 'Completed' ? Colors.grey : const Color(0xFF1E293B),
              decoration: status == 'Completed' ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: _buildStatusBadge(status, statusColor),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statusActionButton('Pending', Colors.grey, status == 'Pending', index, chapters),
                      const SizedBox(width: 8),
                      _statusActionButton('In Progress', Colors.orange, status == 'In Progress', index, chapters),
                      const SizedBox(width: 8),
                      _statusActionButton('Completed', Colors.green, status == 'Completed', index, chapters),
                      const Spacer(),
                      if (!widget.isReadOnly)
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.indigo),
                          onPressed: () => _editChapterName(index, ch['name'], chapters),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _statusActionButton(String label, Color color, bool isActive, int index, List<dynamic> chapters) {
    return InkWell(
      onTap: widget.isReadOnly ? null : () => _updateChapterStatus(index, label, chapters),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : Colors.grey[200]!),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Future<void> _updateChapterStatus(int index, String status, List<dynamic> currentChapters) async {
    List<dynamic> updated = List.from(currentChapters);
    updated[index]['status'] = status;
    
    // Update main progress too
    int completed = updated.where((c) => c['status'] == 'Completed').length;
    double progress = completed / updated.length;

    await _firestore.collection('syllabuses').doc(widget.syllabusId).update({
      'chapters': updated,
      'progress': progress,
    });

    // Notify Admin/Principal if chapter is completed
    if (status == 'Completed') {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.role == 'teacher') {
        NotificationService().sendBroadcastNotification(
          'Chapter Completed: ${widget.subjectName}',
          '${auth.userName} marked "${updated[index]['name']}" as Completed in ${widget.className}.',
          targetRole: 'principal',
        );
      }
    }
  }

  Future<void> _editChapterName(int index, String currentName, List<dynamic> currentChapters) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Chapter Name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      List<dynamic> updated = List.from(currentChapters);
      updated[index]['name'] = newName;
      await _firestore.collection('syllabuses').doc(widget.syllabusId).update({
        'chapters': updated,
      });
    }
  }
}
