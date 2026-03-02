import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/chat_database_service.dart';
import '../../data/services/school_config_service.dart';
import '../../core/constants/app_constants.dart';

class AIBotScreen extends StatefulWidget {
  const AIBotScreen({super.key});

  @override
  State<AIBotScreen> createState() => _AIBotScreenState();
}

class _AIBotScreenState extends State<AIBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatDatabaseService _dbService = ChatDatabaseService();
  
  int? _currentSessionId;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  List<ChatSessionData> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _dbService.getSessions();
    setState(() {
      _history = history;
    });
  }

  Future<void> _startNewSession() async {
    final id = await _dbService.createSession("New Doubt - ${DateFormat('MMM d, h:mm a').format(DateTime.now())}");
    setState(() {
      _currentSessionId = id;
      _messages = [];
    });
    _loadHistory();
    Navigator.pop(context); // Close drawer
  }

  Future<void> _loadSession(int sessionId) async {
    final messages = await _dbService.getMessages(sessionId);
    setState(() {
      _currentSessionId = sessionId;
      _messages = messages;
    });
    Navigator.pop(context); // Close drawer
    _scrollToBottom();
  }

  Future<void> _deleteSession(int sessionId) async {
    await _dbService.deleteSession(sessionId);
    if (_currentSessionId == sessionId) {
      setState(() {
        _currentSessionId = null;
        _messages = [];
      });
    }
    _loadHistory();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_currentSessionId == null) {
      _currentSessionId = await _dbService.createSession(text.length > 30 ? "${text.substring(0, 30)}..." : text);
      _loadHistory();
    }

    final userMsg = ChatMessage(
      sessionId: _currentSessionId!,
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _messageController.clear();
    });
    _scrollToBottom();

    await _dbService.addMessage(userMsg);

    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      
      // Build history for context memory
      final historyForAi = _messages.map((m) => Content(
        role: m.role == 'user' ? 'user' : 'assistant',
        text: m.text,
      )).toList();

      final chat = ChatSession(
        service: aiService,
        history: historyForAi,
        systemPrompt: "You are a helpful and encouraging student AI tutor. Your role is to solve doubts for students in a clear, simple, and step-by-step manner. Use Markdown for formatting. Encourage the student and keep the tone educational.",
      );

      final response = await chat.sendMessage(Content.user(text));
      
      if (response.text != null) {
        final aiMsg = ChatMessage(
          sessionId: _currentSessionId!,
          role: 'assistant',
          text: response.text!,
          timestamp: DateTime.now(),
        );
        await _dbService.addMessage(aiMsg);
        setState(() {
          _messages.add(aiMsg);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<SchoolConfigService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          config.aiAgentName,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87),
            onPressed: _startNewSession,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    const Text(
                      "Chat History",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("New Chat"),
              onTap: _startNewSession,
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final session = _history[index];
                  return ListTile(
                    title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(DateFormat('MMM d, h:mm a').format(session.updatedAt)),
                    onTap: () => _loadSession(session.id!),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteSession(session.id!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isAi = msg.role == 'assistant';
                          return _buildChatBubble(msg.text, isAi);
                        },
                      ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black12),
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildInputArea(),
          ),
        ],
      ),
    );
  }

    final config = Provider.of<SchoolConfigService>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: const Icon(Icons.psychology_outlined, size: 32, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Text(
            config.aiAgentName,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ask me any question or solve your doubts instantly.",
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isAi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(isAi),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAi ? Provider.of<SchoolConfigService>(context, listen: false).aiAgentName : 'You',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isAi)
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  )
                else
                  MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      h1: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.5),
                      h2: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.5),
                      h3: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.5),
                      p: GoogleFonts.inter(fontSize: 15, color: Colors.black87, height: 1.4),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      listBullet: const TextStyle(color: Colors.black54),
                      horizontalRuleDecoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isAi) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: !isAi ? Colors.grey.shade200 : Colors.black87,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: Icon(
          !isAi ? Icons.person_outline_rounded : Icons.psychology_outlined,
          size: 18,
          color: !isAi ? Colors.black54 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.4],
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: Colors.grey.shade400),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: 5,
                minLines: 1,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type your doubt...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        height: 36,
        width: 36,
        decoration: const BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
