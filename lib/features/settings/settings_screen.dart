import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('App Settings'),
            subtitle: Text('Configuration and preferences'),
            leading: Icon(Icons.settings),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "App is locked to Light Theme for optimal visual experience.",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          // Add more settings here later
        ],
      ),
    );
  }
}
