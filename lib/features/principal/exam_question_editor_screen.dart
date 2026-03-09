import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/exam_question_model.dart';
import '../../data/services/exam_question_service.dart';
import '../../data/services/class_service.dart';
import '../../data/services/school_info_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/class_model.dart';
import '../../data/models/scheduled_exam_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExamQuestionEditorScreen extends StatefulWidget {
  final ScheduledExam exam;
  final ExamQuestionPaper? paper;
  final String? selectedClassInitial;

  const ExamQuestionEditorScreen({super.key, required this.exam, this.paper, this.selectedClassInitial});

  @override
  _ExamQuestionEditorScreenState createState() => _ExamQuestionEditorScreenState();
}

class _ExamQuestionEditorScreenState extends State<ExamQuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExamQuestionService _service = ExamQuestionService();
  final ScrollController _mainScrollController = ScrollController();

  late TextEditingController _schoolNameController;
  late TextEditingController _addressController;
  late TextEditingController _examNameController;
  late TextEditingController _sessionController;
  late TextEditingController _subjectController;
  late TextEditingController _timeLimitController;
  late TextEditingController _fullMarksController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassName;

  List<SectionController> _sectionControllers = [];
  int _activeSectionIndex = 0;
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  TextEditingController? _activeController;

  @override
  void initState() {
    super.initState();
    final p = widget.paper;
    _schoolNameController = TextEditingController(text: p?.schoolName ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _examNameController = TextEditingController(text: p?.examName ?? widget.exam.name);
    _sessionController = TextEditingController(text: p?.session ?? '2025-26');
    _subjectController = TextEditingController(text: p?.subject ?? '');
    _timeLimitController = TextEditingController(text: p?.timeLimit ?? '3 Hrs.');
    _fullMarksController = TextEditingController(text: p?.fullMarks.toString() ?? '80');
    _selectedDate = p?.date ?? widget.exam.startDate;
    _selectedClassName = p?.className ?? widget.selectedClassInitial;

    if (p != null) {
      _sectionControllers = p.sections.map((s) => SectionController.fromModel(s)).toList();
    } else {
      _sectionControllers = [
        SectionController(
          title: TextEditingController(text: 'I. निम्नलिखित प्रश्नों के उत्तर दें-'),
          marksLabel: TextEditingController(text: '[10 x 1 = 10]'),
          items: [ItemController(questionText: TextEditingController(text: ''), marks: TextEditingController(text: ''))],
        )
      ];
    }

    if (p == null) {
      _loadSchoolInfo();
    }
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (errorNotification) => debugPrint('Speech error: $errorNotification'),
      );
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
  }

  void _toggleListening(TextEditingController controller) async {
    if (!_isListening) {
      if (!kIsWeb) {
        var status = await Permission.microphone.status;
        if (status.isDenied) {
          await Permission.microphone.request();
        }
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
              _activeController = null;
            });
          }
        },
        onError: (errorNotification) {
          debugPrint('Speech error: $errorNotification');
          setState(() {
            _isListening = false;
            _activeController = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorNotification.errorMsg}')),
          );
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _activeController = controller;
          _lastWords = ''; // Reset for new recognition
        });
        
        final String originalText = controller.text;

        _speech.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
              // Update text in real-time
              if (originalText.isEmpty) {
                controller.text = _lastWords;
              } else {
                controller.text = "$originalText $_lastWords";
              }
              
              if (result.finalResult) {
                _isListening = false;
                _activeController = null;
              }
            });
          },
          localeId: 'hi-IN', // Hindi support
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition not available on this device')),
        );
      }
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
        _activeController = null;
      });
    }
  }

  Future<void> _loadSchoolInfo() async {
    final info = await Provider.of<SchoolInfoService>(context, listen: false).getSchoolInfo();
    if (info != null) {
      setState(() {
        _schoolNameController.text = info['name'] ?? info['schoolName'] ?? '';
        _addressController.text = info['address'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _schoolNameController.dispose();
    _addressController.dispose();
    _examNameController.dispose();
    _sessionController.dispose();
    _subjectController.dispose();
    _timeLimitController.dispose();
    _fullMarksController.dispose();
    for (var sc in _sectionControllers) {
      sc.dispose();
    }
    super.dispose();
  }

  void _addSection() {
    setState(() {
      _sectionControllers.add(SectionController(
        title: TextEditingController(),
        marksLabel: TextEditingController(),
        items: [ItemController(questionText: TextEditingController(), marks: TextEditingController())],
      ));
      _activeSectionIndex = _sectionControllers.length - 1;
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sectionControllers[index].dispose();
      _sectionControllers.removeAt(index);
      if (_activeSectionIndex >= _sectionControllers.length) {
        _activeSectionIndex = _sectionControllers.isEmpty ? 0 : _sectionControllers.length - 1;
      }
    });
  }

  void _addItem(int sectionIndex) {
    setState(() {
      _sectionControllers[sectionIndex].items.add(
        ItemController(questionText: TextEditingController(), marks: TextEditingController()),
      );
    });
  }

  void _removeItem(int sectionIndex, int itemIndex) {
    setState(() {
      _sectionControllers[sectionIndex].items[itemIndex].dispose();
      _sectionControllers[sectionIndex].items.removeAt(itemIndex);
    });
  }

  void _addSubQuestion(int sectionIndex, int itemIndex) {
    setState(() {
      _sectionControllers[sectionIndex].items[itemIndex].subQuestions.add(TextEditingController());
    });
  }

  void _removeSubQuestion(int sectionIndex, int itemIndex, int subIndex) {
    setState(() {
      _sectionControllers[sectionIndex].items[itemIndex].subQuestions[subIndex].dispose();
      _sectionControllers[sectionIndex].items[itemIndex].subQuestions.removeAt(subIndex);
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedClassName == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please select a class'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      final paper = ExamQuestionPaper(
        id: widget.paper?.id ?? '',
        examId: widget.exam.id,
        schoolName: _schoolNameController.text,
        address: _addressController.text,
        examName: _examNameController.text,
        session: _sessionController.text,
        className: _selectedClassName!,
        subject: _subjectController.text,
        date: _selectedDate,
        timeLimit: _timeLimitController.text,
        fullMarks: int.tryParse(_fullMarksController.text) ?? 80,
        sections: _sectionControllers.map((sc) => sc.toModel()).toList(),
        createdAt: widget.paper?.createdAt ?? DateTime.now(),
      );

      await _service.saveQuestionPaper(paper);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.paper == null ? 'Create Question Paper' : 'Edit Question Paper', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)
        ),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text("Save Paper"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.modernPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _mainScrollController,
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactHeader(),
                    const SizedBox(height: 32),
                    if (_sectionControllers.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: _sectionControllers.asMap().entries.map((entry) {
                          return _buildSectionEditor(entry.key, entry.value);
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sections", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppColors.modernPrimary),
                  onPressed: _addSection,
                )
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView(
              padding: EdgeInsets.symmetric(horizontal: 12),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _sectionControllers.removeAt(oldIndex);
                  _sectionControllers.insert(newIndex, item);
                });
              },
              children: _sectionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final sc = entry.value;
                final isActive = _activeSectionIndex == index;
                
                return ListTile(
                  key: ValueKey(sc),
                  onTap: () {
                    setState(() => _activeSectionIndex = index);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  selected: isActive,
                  selectedTileColor: AppColors.modernPrimary.withOpacity(0.08),
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: isActive ? AppColors.modernPrimary : Colors.grey.shade200,
                    child: Text("${index + 1}", style: TextStyle(fontSize: 10, color: isActive ? Colors.white : Colors.grey)),
                  ),
                  title: Text(
                    sc.title.text.isEmpty ? "Untitled Section" : sc.title.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13, 
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppColors.modernPrimary : Colors.black87,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                    onPressed: () => _removeSection(index),
                  ),
                );
              }).toList(),
            ),
          ),
          _buildQuickTips(),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: AppColors.modernPrimary),
              SizedBox(width: 8),
              Text("Editor Tip", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.modernPrimary)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Use the sidebar to jump between sections. You can drag sections to reorder them.",
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.modernPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.school_outlined, color: AppColors.modernPrimary),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Paper Configuration", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Define the basic details of the question paper", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField(_schoolNameController, "School Name", Icons.account_balance)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_addressController, "Location/Address", Icons.location_on_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(_examNameController, "Examination Name", Icons.assignment_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_sessionController, "Session", Icons.calendar_today_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<ClassModel>>(
                  stream: Provider.of<ClassService>(context, listen: false).getAllClasses(),
                  builder: (context, snapshot) {
                    final classes = snapshot.data ?? [];
                    classes.sort((a, b) {
                      final indexA = AppConstants.schoolClasses.indexOf(a.name);
                      final indexB = AppConstants.schoolClasses.indexOf(b.name);
                      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
                      return a.name.compareTo(b.name);
                    });
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedClassName,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Standard / Class',
                        prefixIcon: Icon(Icons.class_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                      items: classes.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _selectedClassName = v),
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_subjectController, "Subject", Icons.book_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_fullMarksController, "Max Marks", Icons.star_border, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_timeLimitController, "Duration", Icons.timer_outlined)),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_note, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(DateFormat('dd MMM yy').format(_selectedDate), style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        isDense: true,
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildSectionEditor(int sectionIndex, SectionController sc) {
    bool isHindiTitle = RegExp(r'[\u0900-\u097F]').hasMatch(sc.title.text);

    return Container(
      key: ValueKey(sc),
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _activeSectionIndex == sectionIndex ? AppColors.modernPrimary.withOpacity(0.3) : Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.modernPrimary,
                  child: Text("${sectionIndex + 1}", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: sc.title,
                    style: isHindiTitle 
                      ? GoogleFonts.hind(fontSize: 16, fontWeight: FontWeight.bold)
                      : GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Section Instructions (e.g. Write answers...)',
                      border: InputBorder.none,
                      suffixIcon: _buildMicButton(sc.title),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: sc.marksLabel,
                    style: GoogleFonts.outfit(fontSize: 14, color: AppColors.modernPrimary, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '[10 x 1 = 10]',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.stars, size: 16, color: AppColors.modernPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ...sc.items.asMap().entries.map((entry) => _buildItemEditor(sectionIndex, entry.key, entry.value)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _addItem(sectionIndex),
                  icon: Icon(Icons.add_circle_outline, size: 20),
                  label: Text("Add Question"),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemEditor(int sectionIndex, int itemIndex, ItemController ic) {
    final alpha = 'abcdefghijklmnopqrstuvwxyz';
    bool isHindi = RegExp(r'[\u0900-\u097F]').hasMatch(ic.questionText.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 30,
                child: Text("${alpha[itemIndex]})", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Expanded(
                child: TextFormField(
                  controller: ic.questionText,
                  maxLines: null,
                  style: isHindi 
                    ? GoogleFonts.hind(fontSize: 15)
                    : GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Type your question here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
                    filled: true,
                    fillColor: Color(0xFFFCFCFD),
                    contentPadding: EdgeInsets.all(16),
                    suffixIcon: _buildMicButton(ic.questionText),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                child: TextFormField(
                  controller: ic.marks,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '[4]',
                    labelText: 'Marks',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep_outlined, color: Colors.grey.shade400, size: 20),
                onPressed: () => _removeItem(sectionIndex, itemIndex),
              ),
            ],
          ),
          if (ic.subQuestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 12),
              child: Column(
                children: ic.subQuestions.asMap().entries.map((subEntry) => _buildSubItemEditor(sectionIndex, itemIndex, subEntry.key, subEntry.value)).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addSubQuestion(sectionIndex, itemIndex),
                icon: Icon(Icons.add_link, size: 16),
                label: Text("Add sub-item (i, ii...)", style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItemEditor(int sectionIndex, int itemIndex, int subIndex, TextEditingController subController) {
    final roman = ['i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x'];
    bool isHindi = RegExp(r'[\u0900-\u097F]').hasMatch(subController.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text("${roman[subIndex]})", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: TextFormField(
              controller: subController,
              style: isHindi 
                ? GoogleFonts.hind(fontSize: 14)
                : GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Sub-question detail...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade100)),
                suffixIcon: _buildMicButton(subController),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey.shade300),
            onPressed: () => _removeSubQuestion(sectionIndex, itemIndex, subIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.description_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text("No sections added yet", style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _addSection, child: Text("Add First Section")),
        ],
      ),
    );
  }

  Widget _buildMicButton(TextEditingController controller) {
    bool isThisActive = _isListening && _activeController == controller;
    return IconButton(
      icon: Icon(
        isThisActive ? Icons.mic : Icons.mic_none,
        color: isThisActive ? Colors.blue : Colors.grey.shade400,
        size: 20,
      ),
      onPressed: () => _toggleListening(controller),
      tooltip: 'Voice Search (Hindi/English)',
    );
  }
}

class SectionController {
  final TextEditingController title;
  final TextEditingController marksLabel;
  final List<ItemController> items;

  SectionController({required this.title, required this.marksLabel, required this.items});

  factory SectionController.fromModel(QuestionSection section) {
    return SectionController(
      title: TextEditingController(text: section.title),
      marksLabel: TextEditingController(text: section.marksLabel),
      items: section.items.map((i) => ItemController.fromModel(i)).toList(),
    );
  }

  QuestionSection toModel() {
    return QuestionSection(
      title: title.text,
      marksLabel: marksLabel.text,
      items: items.map((ic) => ic.toModel()).toList(),
    );
  }

  void dispose() {
    title.dispose();
    marksLabel.dispose();
    for (var i in items) {
      i.dispose();
    }
  }
}

class ItemController {
  final TextEditingController questionText;
  final TextEditingController marks;
  final List<TextEditingController> subQuestions;

  ItemController({required this.questionText, required this.marks, this.subQuestions = const []});

  factory ItemController.fromModel(QuestionItem item) {
    return ItemController(
      questionText: TextEditingController(text: item.questionText),
      marks: TextEditingController(text: item.marks ?? ''),
      subQuestions: item.subQuestions.map((s) => TextEditingController(text: s)).toList(),
    );
  }

  QuestionItem toModel() {
    return QuestionItem(
      questionText: questionText.text,
      marks: marks.text.isEmpty ? null : marks.text,
      subQuestions: subQuestions.map((c) => c.text).toList(),
    );
  }

  void dispose() {
    questionText.dispose();
    marks.dispose();
    for (var sq in subQuestions) {
      sq.dispose();
    }
  }
}
