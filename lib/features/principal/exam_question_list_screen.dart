import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/exam_question_model.dart';
import '../../data/services/exam_question_service.dart';
import '../../data/services/class_service.dart';
import '../../data/models/class_model.dart';
import '../../core/constants/app_constants.dart';
import 'exam_question_editor_screen.dart';
import '../../data/services/exam_question_pdf_service.dart';
import '../../data/models/scheduled_exam_model.dart';

class ExamQuestionListScreen extends StatefulWidget {
  final ScheduledExam exam;

  ExamQuestionListScreen({required this.exam});

  @override
  _ExamQuestionListScreenState createState() => _ExamQuestionListScreenState();
}

class _ExamQuestionListScreenState extends State<ExamQuestionListScreen> {
  final ExamQuestionService _service = ExamQuestionService();
  String? _selectedClassName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: _selectedClassName != null 
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => setState(() => _selectedClassName = null),
            )
          : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedClassName ?? 'Question Repository', 
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            Text(widget.exam.name, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
      body: _selectedClassName == null ? _buildFolderGrid() : _buildPapersList(),
      floatingActionButton: _selectedClassName != null 
        ? FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => ExamQuestionEditorScreen(
                exam: widget.exam,
                selectedClassInitial: _selectedClassName,
              )),
            ),
            icon: Icon(Icons.add),
            label: Text('New Paper', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.modernPrimary,
          )
        : null,
    );
  }

  Widget _buildFolderGrid() {
    return StreamBuilder<List<ClassModel>>(
      stream: Provider.of<ClassService>(context, listen: false).getAllClasses(),
      builder: (context, classSnapshot) {
        if (classSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        return StreamBuilder<List<ExamQuestionPaper>>(
          stream: _service.getQuestionPapers(widget.exam.id),
          builder: (context, paperSnapshot) {
            if (paperSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Error loading folders: ${paperSnapshot.error}', style: TextStyle(color: Colors.red)),
                ),
              );
            }
            if (paperSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final classes = classSnapshot.data ?? [];
            classes.sort((a, b) => a.name.compareTo(b.name));
            final papers = paperSnapshot.data ?? [];

            // Calculate counts
            Map<String, int> counts = {};
            for (var paper in papers) {
              counts[paper.className] = (counts[paper.className] ?? 0) + 1;
            }

            if (classes.isEmpty) {
              return Center(child: Text('No classes found.', style: GoogleFonts.outfit()));
            }

            return GridView.builder(
              padding: EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.9,
              ),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final className = classes[index].name;
                final count = counts[className] ?? 0;
                
                return _buildFolderCard(className, count);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFolderCard(String className, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedClassName = className),
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
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(Icons.folder_rounded, size: 42, color: Colors.blue[600]),
                    if (count > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Class $className',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  count == 1 ? '1 Paper' : '$count Papers',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[500],
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

  Widget _buildPapersList() {
    return StreamBuilder<List<ExamQuestionPaper>>(
      stream: _service.getQuestionPapers(widget.exam.id, className: _selectedClassName),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading papers: ${snapshot.error}', style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: () => setState(() {}), child: Text('Retry')),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                   padding: EdgeInsets.all(24),
                   decoration: BoxDecoration(
                     color: Colors.grey[100],
                     shape: BoxShape.circle,
                   ),
                   child: Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                ),
                SizedBox(height: 24),
                Text(
                  'No question papers yet', 
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])
                ),
                Text(
                  'Click the + button to create a new paper for Class $_selectedClassName', 
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final papers = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: papers.length,
          itemBuilder: (context, index) {
            final paper = papers[index];
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  paper.subject, 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM yyyy').format(paper.date),
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.assignment_outlined, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Text(
                        '${paper.fullMarks} Marks',
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                trailing: Container(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.print_rounded,
                        color: Colors.blue[600]!,
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Preparing PDF... Please wait.')),
                          );
                          final error = await ExamQuestionPdfService.generateAndPrint(paper);
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Print Error: $error'), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        color: Colors.amber[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => ExamQuestionEditorScreen(
                            exam: widget.exam, 
                            paper: paper,
                            selectedClassInitial: paper.className,
                          )),
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete_rounded,
                        color: Colors.red[400]!,
                        onTap: () => _showDeleteDialog(paper),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showDeleteDialog(ExamQuestionPaper paper) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Paper?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete the question paper for Class ${paper.className} - ${paper.subject}?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey[600]))
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.deleteQuestionPaper(paper.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
