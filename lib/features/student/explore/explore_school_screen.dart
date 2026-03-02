import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/student_query_service.dart';
import '../../../data/services/school_config_service.dart';
import '../../../core/constants/app_constants.dart'; // Ensure logo path if available

class ExploreSchoolScreen extends StatefulWidget {
  @override
  _ExploreSchoolScreenState createState() => _ExploreSchoolScreenState();
}

class _ExploreSchoolScreenState extends State<ExploreSchoolScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _messages = []; 
  bool _isTyping = false;
  ChatSession? _chatSession;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startChat();
  }

  Future<void> _startChat() async {
    final aiService = Provider.of<AIService>(context, listen: false);
    final config = Provider.of<SchoolConfigService>(context, listen: false);
    _chatSession = await aiService.startChatSession();
    setState(() {
      _messages.add({
        'role': 'ai',
        'text': "Hello! I am **${config.aiAgentName}**. Ask me anything about the school!"
      });
    });
  }

  Future<void> _askAI() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isTyping = true;
      _queryController.clear();
    });
    _scrollToBottom();

    try {
      String responseText = "I'm having trouble connecting.";
      
      if (_chatSession != null) {
        final response = await _chatSession!.sendMessage(Content.user(query));
        responseText = response.text ?? "I didn't understand that.";
      }

      // Save to Firestore (Async, don't wait)
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.user != null) {
        Provider.of<StudentQueryService>(context, listen: false).submitQuery(
          userId: authService.user!.uid, 
          userName: authService.userName, 
          query: query, 
          aiResponse: responseText
        );
      }

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'ai', 'text': responseText});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'ai', 'text': "Error: Unable to get response. Please try again."});
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Explore Veena Public School"),
        elevation: 0,
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                /*image: DecorationImage(
                  image: AssetImage('assets/images/school_bg_pattern.png'), // Optional BG pattern
                  fit: BoxFit.cover,
                  opacity: 0.1
                ),*/
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return _buildChatBubble(msg['text']!, isUser);
                },
              ),
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                     backgroundColor: Colors.blue[800],
                     radius: 12,
                     child: Icon(Icons.psychology, size: 16, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text("${Provider.of<SchoolConfigService>(context, listen: false).aiAgentName} is typing...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
            bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
          ),
          boxShadow: [
             if (!isUser) BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      Icon(Icons.psychology, size: 14, color: Colors.blue[800]),
                      SizedBox(width: 4),
                      Text(Provider.of<SchoolConfigService>(context, listen: false).aiAgentName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                   ],
                ),
              ),
            isUser 
             ? Text(text, style: TextStyle(color: Colors.white, fontSize: 15))
             : MarkdownBody(
                 data: text,
                 styleSheet: MarkdownStyleSheet(
                   p: TextStyle(color: Colors.black87, fontSize: 15, height: 1.4),
                   strong: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                   listBullet: TextStyle(color: Colors.blue[800]),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: "Ask anything...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _askAI(),
            ),
          ),
          SizedBox(width: 12),
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.blue[800],
            child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            onPressed: isTyping ? null : _askAI, // Disable if typing
          ),
        ],
      ),
    );
  }

  bool get isTyping => _isTyping;
}

