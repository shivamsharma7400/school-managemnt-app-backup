import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/test_model.dart';
import '../../../data/services/test_service.dart';
import '../../../data/services/auth_service.dart';
import '../../common/widgets/class_dropdown.dart';
import '../../../core/constants/app_constants.dart';

class CreateTestScreen extends StatefulWidget {
  @override
  _CreateTestScreenState createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Test Details
  String _title = '';
  String _description = '';
  String? _classId;
  String _subject = '';
  int _durationMinutes = 10;
  List<Question> _questions = [];

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text('Create Online Test'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Test Details"),
                    SizedBox(height: 16),
                    _buildTestDetailsCard(),
                    
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader("Questions (${_questions.length})"),
                        TextButton.icon(
                          onPressed: () => _showAddQuestionSheet(context),
                          icon: Icon(Icons.add_circle, color: AppColors.primary),
                          label: Text("Add New", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    if (_questions.isEmpty)
                      _buildEmptyState()
                    else
                      ..._questions.asMap().entries.map((entry) => _buildQuestionPreview(entry.key, entry.value)).toList(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
    );
  }

  Widget _buildTestDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          TextFormField(
            decoration: _inputDecoration('Test Title', Icons.title),
            validator: (val) => val!.isEmpty ? 'Enter title' : null,
            onSaved: (val) => _title = val!,
          ),
          SizedBox(height: 16),
          TextFormField(
            decoration: _inputDecoration('Description', Icons.description),
            onSaved: (val) => _description = val ?? '',
            maxLines: 2,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClassDropdown(
                  value: _classId,
                  onChanged: (val) => setState(() => _classId = val),
                  validator: (val) => val == null ? 'Select Class' : null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: _inputDecoration('Subject', Icons.book),
                  validator: (val) => val!.isEmpty ? 'Enter subject' : null,
                  onSaved: (val) => _subject = val!,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            decoration: _inputDecoration('Duration (Minutes)', Icons.timer),
            keyboardType: TextInputType.number,
            initialValue: '10',
            validator: (val) => int.tryParse(val!) == null ? 'Enter valid number' : null,
            onSaved: (val) => _durationMinutes = int.parse(val!),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.indigo.shade300),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade300),
          SizedBox(height: 12),
          Text("No questions added yet", style: TextStyle(color: Colors.grey)),
          SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _showAddQuestionSheet(context),
            child: Text("Add First Question"),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionPreview(int index, Question q) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 32, height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Text('${index + 1}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(q.text, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Chip(
                label: Text(q.type == 'mcq' ? 'MCQ' : 'Fill Blank', style: TextStyle(fontSize: 10, color: Colors.white)),
                backgroundColor: q.type == 'mcq' ? Colors.orange : Colors.teal,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              SizedBox(width: 8),
              Expanded(child: Text('Ans: ${q.correctAnswer}', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
          onPressed: () {
            setState(() {
              _questions.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting 
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : Text('PUBLISH TEST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        ),
      ),
    );
  }

  void _showAddQuestionSheet(BuildContext context) {
    String qText = '';
    String qType = 'mcq';
    String op1 = '', op2 = '', op3 = '', op4 = '';
    String? selectedOptionIndex; 
    String correctAnsText = ''; 
    final _qFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 8, bottom: 8),
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  Text("Add New Question", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Form(
                        key: _qFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              decoration: _inputDecoration('Question Text', Icons.help_outline),
                              validator: (val) => val!.isEmpty ? 'Required' : null,
                              onChanged: (val) => qText = val,
                              maxLines: 2,
                            ),
                            SizedBox(height: 20),
                            Text("Question Type", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text("MCQ"),
                                    value: 'mcq',
                                    groupValue: qType,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) => setSheetState(() => qType = val!),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text("Fill Blank"),
                                    value: 'fill_blank',
                                    groupValue: qType,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) => setSheetState(() => qType = val!),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 16),
                            if (qType == 'mcq') ...[
                              Text("Options", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                              SizedBox(height: 8),
                              _buildOptionField('A', (val) => op1 = val),
                              _buildOptionField('B', (val) => op2 = val),
                              _buildOptionField('C', (val) => op3 = val),
                              _buildOptionField('D', (val) => op4 = val),
                              SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                decoration: _inputDecoration('Correct Answer', Icons.check_circle_outline),
                                items: ['A', 'B', 'C', 'D'].map((e) => DropdownMenuItem(value: e, child: Text("Option $e"))).toList(),
                                onChanged: (val) => selectedOptionIndex = val,
                                validator: (val) => val == null ? 'Select correct option' : null,
                              ),
                            ] else ...[
                              TextFormField(
                                decoration: _inputDecoration('Correct Answer', Icons.check_circle),
                                validator: (val) => val!.isEmpty ? 'Required' : null,
                                onChanged: (val) => correctAnsText = val,
                              ),
                            ],
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_qFormKey.currentState!.validate()) {
                                     String finalCorrectAnswer = '';
                                     
                                     if (qType == 'mcq') {
                                       if (selectedOptionIndex == 'A') finalCorrectAnswer = op1;
                                       else if (selectedOptionIndex == 'B') finalCorrectAnswer = op2;
                                       else if (selectedOptionIndex == 'C') finalCorrectAnswer = op3;
                                       else if (selectedOptionIndex == 'D') finalCorrectAnswer = op4;
                                     } else {
                                       finalCorrectAnswer = correctAnsText;
                                     }
              
                                     final newQ = Question(
                                       id: Uuid().v4(),
                                       text: qText,
                                       type: qType,
                                       options: qType == 'mcq' ? [op1, op2, op3, op4] : [],
                                       correctAnswer: finalCorrectAnswer,
                                     );
                                     setState(() {
                                       _questions.add(newQ);
                                     });
                                     Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('SAVE QUESTION', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(height: 100), // Spacing for safe area
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ); 
  }

  // Helper for options
  Widget _buildOptionField(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Option $label',
          prefixText: '$label. ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onChanged: onChanged,
        validator: (val) => val!.isEmpty ? 'Required' : null,
      ),
    );
  }

  void _submitTest() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (_questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add at least one question')));
        return;
      }

      setState(() => _isSubmitting = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final testService = Provider.of<TestService>(context, listen: false);

      final test = Test(
        id: '',
        title: _title,
        description: _description,
        classId: _classId!,
        subject: _subject,
        durationMinutes: _durationMinutes,
        createdBy: authService.user!.uid,
        createdAt: DateTime.now(),
        questions: _questions,
      );

      try {
        await testService.createTest(test);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test Created Successfully')));
        }
      } catch (e) {
        if (mounted) {
           setState(() => _isSubmitting = false);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
