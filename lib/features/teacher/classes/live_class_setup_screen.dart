import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/widgets/class_dropdown.dart';
import '../../../data/services/online_class_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/youtube_service.dart';
import '../../../data/models/online_class_model.dart';

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
          teacherId: authService.currentUserId,
          youtubeVideoId: _videoId,
        );
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class is LIVE!')));
           // Instead of pop, switch to history tab or just clear
           _videoIdController.clear();
           _titleController.clear();
           _descController.clear();
           setState(() {
             _videoId = '';
             _isSubmitting = false;
           });
           DefaultTabController.of(context).animateTo(1);
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Live Class Management', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.live_tv), text: 'Go Live'),
              Tab(icon: Icon(Icons.history), text: 'Past Classes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSetupTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Video Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _videoIdController,
                            decoration: InputDecoration(
                              labelText: 'YouTube Link / ID',
                              hintText: 'Paste full link or ID',
                              prefixIcon: const Icon(Icons.link),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                            onSaved: (val) => _videoId = val!,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isFetching ? null : _fetchVideoDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[50],
                              foregroundColor: Colors.indigo,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isFetching 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_fix_high),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Class Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Class Title',
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                      onSaved: (val) => _title = val!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description_outlined),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 3,
                      onSaved: (val) => _description = val ?? '',
                    ),
                    const SizedBox(height: 16),
                    ClassDropdown(
                      value: _classId,
                      onChanged: (val) => setState(() => _classId = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _goLive,
                icon: const Icon(Icons.rocket_launch),
                label: Text(_isSubmitting ? 'STARTING...' : 'LAUNCH LIVE CLASS', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final classService = Provider.of<OnlineClassService>(context, listen: false);

    return StreamBuilder<List<OnlineClass>>(
      stream: classService.getHistoryForTeacher(authService.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No class history found', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        final classes = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            final isLive = cls.status == 'live';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.red[50] : Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLive ? Icons.sensors : Icons.video_library,
                    color: isLive ? Colors.red : Colors.blue,
                  ),
                ),
                title: Text(cls.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Class: ${cls.classId} • ${cls.startedAt.day}/${cls.startedAt.month}/${cls.startedAt.year}'),
                trailing: isLive
                    ? ElevatedButton(
                        onPressed: () => classService.endClass(cls.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('END'),
                      )
                    : const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}
