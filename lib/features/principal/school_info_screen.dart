import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/school_info_service.dart';

class SchoolInfoScreen extends StatefulWidget {
  @override
  _SchoolInfoScreenState createState() => _SchoolInfoScreenState();
}

class _SchoolInfoScreenState extends State<SchoolInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _timingsController = TextEditingController();
  final _aboutController = TextEditingController();
  final _rulesController = TextEditingController();
  
  // Dynamic fields: List of Maps/Pairs or Controllers
  // We'll store them as a list of "CustomField" objects or just map entries
  final List<Map<String, TextEditingController>> _customFields = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await Provider.of<SchoolInfoService>(context, listen: false).getSchoolInfo();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _addressController.text = data['address'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _timingsController.text = data['timings'] ?? '';
      _aboutController.text = data['about'] ?? '';
      _rulesController.text = data['rules'] ?? '';

      // Load Custom Fields
      if (data['custom_fields'] != null) {
        final Map<String, dynamic> custom = data['custom_fields'];
        _customFields.clear();
        custom.forEach((key, value) {
          _customFields.add({
            'title': TextEditingController(text: key),
            'content': TextEditingController(text: value.toString()),
          });
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        Map<String, dynamic> customData = {};
        for (var field in _customFields) {
          if (field['title']!.text.isNotEmpty && field['content']!.text.isNotEmpty) {
            customData[field['title']!.text.trim()] = field['content']!.text.trim();
          }
        }

        await Provider.of<SchoolInfoService>(context, listen: false).updateSchoolInfo({
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'contact': _contactController.text.trim(),
          'timings': _timingsController.text.trim(),
          'about': _aboutController.text.trim(),
          'rules': _rulesController.text.trim(),
          'custom_fields': customData,
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('School Info Updated')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _addCustomField() {
    setState(() {
      _customFields.add({
        'title': TextEditingController(),
        'content': TextEditingController(),
      });
    });
  }

  void _removeCustomField(int index) {
      setState(() {
        _customFields.removeAt(index);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Train AI (School Info)')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      "Teach Veena AI about your school.\nThe more details you provide, the better it answers.",
                      style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'School Name', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Full Address', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(labelText: 'Contact Details (Phone/Email)', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _timingsController,
                      decoration: InputDecoration(labelText: 'School Timings', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _rulesController,
                      decoration: InputDecoration(labelText: 'Admission Rules & Fees', border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _aboutController,
                      decoration: InputDecoration(labelText: 'About / History / Vision', border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Additional Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addCustomField,
                          icon: Icon(Icons.add),
                          label: Text("Add Field"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        )
                      ],
                    ),
                    Divider(),
                    ..._customFields.asMap().entries.map((entry) {
                      final index = entry.key;
                      final field = entry.value;
                      return Card(
                         margin: EdgeInsets.symmetric(vertical: 8),
                         child: Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: Column(
                             children: [
                               Row(
                                 children: [
                                   Expanded(
                                     flex: 2,
                                     child: TextFormField(
                                       controller: field['title'],
                                       decoration: InputDecoration(
                                          labelText: 'Field Title (e.g. Sports Captain)', 
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(),
                                       ),
                                     ),
                                   ),
                                   IconButton(
                                     icon: Icon(Icons.delete, color: Colors.red),
                                     onPressed: () => _removeCustomField(index),
                                   )
                                 ],
                               ),
                               SizedBox(height: 8),
                               TextFormField(
                                 controller: field['content'],
                                 decoration: InputDecoration(
                                   labelText: 'Description / Content',
                                   border: OutlineInputBorder(),
                                 ),
                                 maxLines: 3,
                               ),
                             ],
                           ),
                         ),
                      );
                    }).toList(),

                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveData,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("Save & Train AI"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
