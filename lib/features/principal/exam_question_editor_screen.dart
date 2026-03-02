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

class ExamQuestionEditorScreen extends StatefulWidget {
  final ScheduledExam exam;
  final ExamQuestionPaper? paper;
  final String? selectedClassInitial;

  ExamQuestionEditorScreen({required this.exam, this.paper, this.selectedClassInitial});

  @override
  _ExamQuestionEditorScreenState createState() => _ExamQuestionEditorScreenState();
}

class _ExamQuestionEditorScreenState extends State<ExamQuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExamQuestionService _service = ExamQuestionService();

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

  @override
  void initState() {
    super.initState();
    final p = widget.paper;
    _schoolNameController = TextEditingController(text: p?.schoolName ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _examNameController = TextEditingController(text: p?.examName ?? widget.exam.name);
    _sessionController = TextEditingController(text: p?.session ?? '2025-2026');
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
          title: TextEditingController(text: 'निम्नलिखित प्रश्नों के उत्तर दें-'),
          marksLabel: TextEditingController(text: '[10 x 1 = 10]'),
          items: [ItemController(questionText: TextEditingController(text: ''), marks: TextEditingController(text: ''))],
        )
      ];
    }

    if (p == null) {
      _loadSchoolInfo();
    }
  }

  Future<void> _loadSchoolInfo() async {
    final info = await Provider.of<SchoolInfoService>(context, listen: false).getSchoolInfo();
    if (info != null) {
      setState(() {
        _schoolNameController.text = info['schoolName'] ?? '';
        _addressController.text = info['address'] ?? '';
      });
    }
  }

  @override
  void dispose() {
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
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sectionControllers[index].dispose();
      _sectionControllers.removeAt(index);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a class'), backgroundColor: Colors.red));
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
      appBar: AppBar(
        title: Text(widget.paper == null ? 'New Question Paper' : 'Edit Question Paper', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              SizedBox(height: 24),
              Text('Questions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ..._sectionControllers.asMap().entries.map((entry) => _buildSectionEditor(entry.key, entry.value)),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addSection,
                  icon: Icon(Icons.library_add),
                  label: Text('Add New Section'),
                ),
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _schoolNameController,
              decoration: InputDecoration(labelText: 'School Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _examNameController,
                    decoration: InputDecoration(labelText: 'Exam Name'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _sessionController,
                    decoration: InputDecoration(labelText: 'Session'),
                  ),
                ),
              ],
            ),
            StreamBuilder<List<ClassModel>>(
              stream: Provider.of<ClassService>(context, listen: false).getAllClasses(),
              builder: (context, snapshot) {
                final classes = snapshot.data ?? [];
                classes.sort((a, b) => a.name.compareTo(b.name));
                return DropdownButtonFormField<String>(
                  value: _selectedClassName,
                  decoration: InputDecoration(labelText: 'Class'),
                  items: classes.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _selectedClassName = v),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(labelText: 'Subject'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _fullMarksController,
                    decoration: InputDecoration(labelText: 'Full Marks'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
                    trailing: Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _timeLimitController,
                    decoration: InputDecoration(labelText: 'Time Limit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionEditor(int sectionIndex, SectionController sc) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text('${sectionIndex + 1}'), radius: 15),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: sc.title,
                    decoration: InputDecoration(hintText: 'Section Title (e.g. Write answers...)'),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: sc.marksLabel,
                    decoration: InputDecoration(hintText: '[10 x 1 = 10]'),
                  ),
                ),
                IconButton(icon: Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => _removeSection(sectionIndex)),
              ],
            ),
            Divider(),
            ...sc.items.asMap().entries.map((entry) => _buildItemEditor(sectionIndex, entry.key, entry.value)),
            TextButton.icon(
              onPressed: () => _addItem(sectionIndex),
              icon: Icon(Icons.add),
              label: Text('Add Question Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemEditor(int sectionIndex, int itemIndex, ItemController ic) {
    final alpha = 'abcdefghijklmnopqrstuvwxyz';
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('${alpha[itemIndex]}) ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: TextFormField(
                  controller: ic.questionText,
                  decoration: InputDecoration(hintText: 'Enter question text...'),
                  maxLines: null,
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: ic.marks,
                  decoration: InputDecoration(hintText: '[4]'),
                ),
              ),
              IconButton(icon: Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey), onPressed: () => _removeItem(sectionIndex, itemIndex)),
            ],
          ),
          ...ic.subQuestions.asMap().entries.map((subEntry) => _buildSubItemEditor(sectionIndex, itemIndex, subEntry.key, subEntry.value)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addSubQuestion(sectionIndex, itemIndex),
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Sub-Question (i, ii...)', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItemEditor(int sectionIndex, int itemIndex, int subIndex, TextEditingController subController) {
    final roman = ['i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x'];
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4),
      child: Row(
        children: [
          Text('${roman[subIndex]}) ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: TextFormField(
              controller: subController,
              decoration: InputDecoration(hintText: 'Sub-question text...', isDense: true),
              style: TextStyle(fontSize: 13),
            ),
          ),
          IconButton(icon: Icon(Icons.close, size: 16, color: Colors.grey), onPressed: () => _removeSubQuestion(sectionIndex, itemIndex, subIndex)),
        ],
      ),
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

extension CardExtension on Card {
  Widget padding(EdgeInsets padding) => Padding(padding: padding, child: this);
}
