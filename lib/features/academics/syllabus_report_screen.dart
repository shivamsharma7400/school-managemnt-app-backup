import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_detail_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/auth_service.dart';
import 'package:provider/provider.dart';

class SyllabusReportScreen extends StatefulWidget {
  final bool isClassTeacherMode;
  final bool isSubjectTeacherMode;
  final bool isReadOnly;

  const SyllabusReportScreen({
    Key? key,
    this.isClassTeacherMode = false,
    this.isSubjectTeacherMode = false,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  _SyllabusReportScreenState createState() => _SyllabusReportScreenState();
}

class _SyllabusReportScreenState extends State<SyllabusReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedClassId;
  String? _selectedClassName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isClassTeacherMode) {
      _loadClassTeacherClass();
    }
  }

  Future<void> _loadClassTeacherClass() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      final classSnap = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (classSnap.docs.isNotEmpty) {
        setState(() {
          _selectedClassId = classSnap.docs.first.id;
          _selectedClassName = classSnap.docs.first.data()['name'];
        });
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _selectedClassName == null ? 'Syllabus Repository' : 'Class $_selectedClassName Syllabus',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: (_selectedClassId != null && !widget.isClassTeacherMode)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => setState(() {
                _selectedClassId = null;
                _selectedClassName = null;
              }),
            )
          : null,
        actions: [
          if (_selectedClassId != null && !widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: _showAddSubjectDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  backgroundColor: Colors.indigo[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.isSubjectTeacherMode) {
      return _buildSubjectTeacherView();
    }

    if (widget.isClassTeacherMode && _selectedClassId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No class assigned to you yet.', style: GoogleFonts.outfit(color: Colors.grey)),
          ],
        ),
      );
    }

    return _selectedClassId == null ? _buildClassGrid() : _buildSubjectView();
  }

  Widget _buildSubjectTeacherView() {
    final user = Provider.of<AuthService>(context, listen: false).user;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('syllabuses')
          .where('teacherId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_stories_outlined, size: 64, color: Colors.indigo[200]),
                ),
                const SizedBox(height: 24),
                Text(
                  'No subjects assigned to you', 
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])
                ),
                const SizedBox(height: 8),
                Text(
                  'Please contact the administrator for assignments.', 
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final subjects = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 1),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 2.5,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final data = subjects[index].data() as Map<String, dynamic>;
            final subjectName = data['subjectName'] ?? 'No Name';
            final progress = (data['progress'] ?? 0.0).toDouble();
            final className = data['className'] ?? 'N/A'; // I should probably store className in syllabus doc for easier display here

            return _buildSubjectCard(subjects[index].id, subjectName, progress, className: className);
          },
        );
      },
    );
  }

  Widget _buildClassGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('classes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No class folders found.', style: GoogleFonts.outfit(color: Colors.grey)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        docs.sort((a, b) => (a.data() as Map)['name'].toString().compareTo((b.data() as Map)['name'].toString()));

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.85,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final className = data['name'] ?? 'Unknown';
            return _buildFolderCard(id, className);
          },
        );
      },
    );
  }

  Widget _buildSubjectView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('syllabuses')
          .where('classId', isEqualTo: _selectedClassId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_stories_outlined, size: 64, color: Colors.indigo[200]),
                ),
                const SizedBox(height: 24),
                Text(
                  'No subjects added for Class $_selectedClassName', 
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])
                ),
                const SizedBox(height: 8),
                Text(
                  'Click "Add Subject" to start building the repository.', 
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final subjects = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 1),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 2.5,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final data = subjects[index].data() as Map<String, dynamic>;
            final subjectName = data['subjectName'] ?? 'No Name';
            final progress = (data['progress'] ?? 0.0).toDouble();

            return _buildSubjectCard(subjects[index].id, subjectName, progress);
          },
        );
      },
    );
  }

  Widget _buildFolderCard(String id, String className) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedClassId = id;
            _selectedClassName = className;
          }),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(Icons.folder_rounded, size: 42, color: Colors.indigo),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Class $className',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'View Subjects',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.indigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(String id, String name, double progress, {String? className}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Find class name from context if not provided
            String resolvedClassName = className ?? _selectedClassName ?? 'Unknown';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => SubjectDetailScreen(
                  syllabusId: id,
                  subjectName: name,
                  className: resolvedClassName,
                  isReadOnly: widget.isReadOnly,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (className != null)
                            Text(
                              'Class $className',
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                    if (['principal', 'admin'].contains(Provider.of<AuthService>(context, listen: false).role))
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Delete Subject', style: TextStyle(color: Colors.red)),
                            onTap: () => _firestore.collection('syllabuses').doc(id).delete(),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.green : Colors.indigo),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}% Course Completed',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add New Subject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Subject Name (e.g. Science)',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _firestore.collection('syllabuses').add({
                  'classId': _selectedClassId,
                  'subjectName': controller.text.trim(),
                  'progress': 0.0,
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Subject'),
          ),
        ],
      ),
    );
  }
}
