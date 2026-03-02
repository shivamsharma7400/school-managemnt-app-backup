
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/migration_service.dart';

class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({super.key});

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  final MigrationService _migrationService = MigrationService();
  String _selectedRole = 'student';
  List<Map<String, dynamic>> _previewData = [];
  bool _isImporting = false;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.bytes != null) {
      final String csvString = utf8.decode(result.files.single.bytes!);
      setState(() {
        _fileName = result.files.single.name;
        _previewData = _migrationService.parseCsv(csvString);
      });
    }
  }

  Future<void> _importData() async {
    if (_previewData.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final int count = await _migrationService.importData(_selectedRole, _previewData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count $_selectedRole records!')),
        );
        setState(() {
          _previewData = [];
          _fileName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showSampleFormat() {
    final String sample = _migrationService.getSampleCsv(_selectedRole);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Expected CSV Format ($_selectedRole)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The CSV should have the following headers:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: SelectableText(sample.split('\n').first),
              ),
              const SizedBox(height: 16),
              const Text('Example row:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: SelectableText(sample.split('\n')[1]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Data Migration', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSelectionRow(),
            const SizedBox(height: 24),
            _buildUploadSection(),
            const SizedBox(height: 24),
            if (_previewData.isNotEmpty) ...[
              const Text('Data Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(child: _buildPreviewTable()),
              const SizedBox(height: 24),
              _buildImportButton(),
            ] else if (_fileName != null)
               const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No data found in file.')))
            else
               const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Import Old School Data',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Quickly migrate your students and staff data from CSV files. Make sure the format matches the requirements.',
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSelectionRow() {
    return Row(
      children: [
        Expanded(
          child: _SelectionCard(
            title: 'Students',
            icon: Icons.school,
            isSelected: _selectedRole == 'student',
            onTap: () => setState(() {
              _selectedRole = 'student';
              _previewData = [];
              _fileName = null;
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SelectionCard(
            title: 'Staff/Teachers',
            icon: Icons.people,
            isSelected: _selectedRole == 'staff',
            onTap: () => setState(() {
              _selectedRole = 'staff';
              _previewData = [];
              _fileName = null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? 'No file selected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _fileName == null ? Colors.grey : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _showSampleFormat,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View expected format'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isImporting ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Pick CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable() {
    if (_previewData.isEmpty) return const SizedBox.shrink();
    
    final headers = _previewData[0].keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              rows: _previewData.take(5).map((row) {
                return DataRow(
                  cells: headers.map((h) => DataCell(Text(row[h]?.toString() ?? ''))).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isImporting ? null : _importData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isImporting
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Import ${_previewData.length} Records', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.indigo : Colors.grey[200]!),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : Colors.indigo),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
