import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class ClassDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final String labelText;

  const ClassDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.labelText = 'Select Class',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
      items: AppConstants.schoolClasses.map((String className) {
        return DropdownMenuItem<String>(
          value: className,
          child: Text('Class $className'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
