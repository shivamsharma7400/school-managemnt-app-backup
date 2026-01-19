import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/widgets/class_dropdown.dart';
import '../../../data/services/online_class_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/youtube_service.dart';

class LiveClassSetupScreen extends StatefulWidget {
  @override
  _LiveClassSetupScreenState createState() => _LiveClassSetupScreenState();
}

class _LiveClassSetupScreenState extends State<LiveClassSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String? _classId;
  String _videoId = ''; 
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _videoIdController = TextEditingController();

  bool _isSubmitting = false;
  bool _isFetching = false;

  void _fetchVideoDetails() async {
    String input = _videoIdController.text.trim();
    if (input.isEmpty) return;

    String? id;
    
    // RegExp to match various YouTube URL formats including live
    // Covers: youtube.com/watch?v=, youtu.be/, youtube.com/live/, youtube.com/embed/
    RegExp regExp = RegExp(
      r'^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=|live\/)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );

    final match = regExp.firstMatch(input);
    if (match != null && match.groupCount >= 2) {
      id = match.group(2);
    } else {
      // Assume input might be just the ID if no URL pattern matches
      // Basic check: ID is usually 11 chars, but we can be lenient or strict
      if (input.length == 11) {
         id = input;
      }
    }

    if (id == null || id.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid Video URL or ID')));
       return;
    }

    setState(() => _isFetching = true);
    final details = await YouTubeService().getVideoDetails(id);
    setState(() => _isFetching = false);

    if (details != null) {
      setState(() {
         _titleController.text = details['title'];
         _descController.text = details['description'];
         _videoIdController.text = id!; // Replace URL with clean ID
         _title = details['title'];
         _description = details['description'];
         _videoId = id!;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video Details Fetched!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not fetch details. Check ID/Link.')));
    }
  }

  void _goLive() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Ensure we use the clean ID if user didn't click fetch but typed cleanly
      if (_videoId.isEmpty) _videoId = _videoIdController.text;

      setState(() => _isSubmitting = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final classService = Provider.of<OnlineClassService>(context, listen: false);

      try {
         await classService.createBroadcast(
          title: _title,
          description: _description,
          classId: _classId!,
          teacherName: authService.userName,
          youtubeVideoId: _videoId,
        );
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Class is LIVE!')));
           Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
           setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Go Live')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
               Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _videoIdController,
                      decoration: InputDecoration(
                        labelText: 'YouTube Link / ID',
                        helperText: 'Paste full link or ID',
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                      onSaved: (val) => _videoId = val!,
                    ),
                  ),
                  SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: _isFetching 
                      ? CircularProgressIndicator()
                      : IconButton(
                          icon: Icon(Icons.cloud_download, color: Colors.blue),
                          onPressed: _fetchVideoDetails,
                          tooltip: 'Fetch Details',
                        ),
                  )
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Class Title'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
                onSaved: (val) => _title = val!,
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (val) => _description = val ?? '',
              ),
              SizedBox(height: 16),
              ClassDropdown(
                value: _classId,
                onChanged: (val) => setState(() => _classId = val),
                 validator: (val) => val == null ? 'Select Class' : null,
              ),
              SizedBox(height: 32),
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _goLive,
                      icon: Icon(Icons.live_tv),
                      label: Text('GO LIVE NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
