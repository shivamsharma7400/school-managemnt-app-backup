import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/school_config_service.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  @override
  _AdvancedSettingsScreenState createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _isEditing = false;
  late TextEditingController _schoolNameController;
  late TextEditingController _logoUrlController;
  late TextEditingController _aiNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final config = Provider.of<SchoolConfigService>(context, listen: false);
    _schoolNameController = TextEditingController(text: config.schoolName);
    _logoUrlController = TextEditingController(text: config.schoolLogoUrl);
    _aiNameController = TextEditingController(text: config.aiAgentName);
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _logoUrlController.dispose();
    _aiNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<SchoolConfigService>(context, listen: false).updateConfig(
        schoolName: _schoolNameController.text,
        schoolLogoUrl: _logoUrlController.text,
        aiAgentName: _aiNameController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settings updated successfully!')),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to update UI if changed externally or initially loaded
    final config = Provider.of<SchoolConfigService>(context);
    
    // Only update controllers if not editing to avoid overwriting user input
    if (!_isEditing) {
        if (_schoolNameController.text != config.schoolName) _schoolNameController.text = config.schoolName;
        if (_logoUrlController.text != config.schoolLogoUrl) _logoUrlController.text = config.schoolLogoUrl;
        if (_aiNameController.text != config.aiAgentName) _aiNameController.text = config.aiAgentName;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Settings (Admin)'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSchoolDetails(context),
            if (_isEditing) ...[
                SizedBox(height: 24),
                Center(
                    child: _isLoading 
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12)
                        ),
                        onPressed: _saveChanges, 
                        child: Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                ),
                SizedBox(height: 12),
                Center(
                    child: TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                    )
                )
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildSchoolDetails(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("School Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _logoUrlController.text.isNotEmpty ? NetworkImage(_logoUrlController.text) : null,
                    child: _logoUrlController.text.isEmpty 
                        ? Icon(Icons.school, size: 40, color: Colors.indigo)
                        : null,
                  ),
                  SizedBox(height: 8),
                  Text("School Logo", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildEditableField("School Name", _schoolNameController, _isEditing),
            SizedBox(height: 12),
            _buildEditableField("School Logo URL", _logoUrlController, _isEditing),
            SizedBox(height: 12),
            _buildEditableField("AI Agent Name", _aiNameController, _isEditing),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEditableField(String label, TextEditingController controller, bool isEditing) {
    if (!isEditing) {
        return _buildReadOnlyField(label, controller.text);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value.isEmpty ? 'Not Set' : value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
      ],
    );
  }
}
