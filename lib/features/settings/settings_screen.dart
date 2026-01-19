import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('App Theme'),
            subtitle: Text('Choose your preferred appearance'),
          ),
          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Enable dark theme'),
            secondary: Icon(Icons.dark_mode),
            value: themeService.isDarkMode,
            onChanged: (value) {
              themeService.toggleTheme(value);
            },
          ),
          // Add more settings here later
        ],
      ),
    );
  }
}
