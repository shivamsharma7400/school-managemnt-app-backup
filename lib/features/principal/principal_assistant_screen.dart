import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/auth_service.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class PrincipalAssistantScreen extends StatelessWidget {
  const PrincipalAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthService>(context, listen: false).role ?? 'Principal';
    final roleTitle = role.toLowerCase() == 'admin' ? 'Admin' : 'Principal';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '$roleTitle\'s AI Assistant',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: _AIChatTab(),
    );
  }
}

class _AIChatTab extends StatefulWidget {
  @override
  __AIChatTabState createState() => __AIChatTabState();
}

class __AIChatTabState extends State<_AIChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  ChatSession? _chatSession;

  final List<String> _suggestedQuestions = [
    "How is the school attendance today?",
    "Show me recent fee transactions.",
    "Are there any pending leave requests?",
    "How many students are pending approval?",
  ];

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _messages.add({
        'role': 'model',
        'text': '_Analyzing school data..._'
      });
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final role = authService.role ?? 'Principal';
      final roleTitle = role.toLowerCase() == 'admin' ? 'Admin' : 'Principal';

      final service = Provider.of<AIService>(context, listen: false);
      _chatSession = await service.startManagementChatSession(role);
      
      setState(() {
        _isLoading = false;
        _messages.removeLast(); // Remove the "Analyzing..." message
        _messages.add({
          'role': 'model',
          'text': 'Hello $roleTitle. **(Data Sync: v2.2)** I have analyzed the latest school reports and student records. How can I assist you with planning, admissions, or budget today?'
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('Principal AI Session Error: $e');
      }
      setState(() {
        _isLoading = false;
        _messages.removeLast();
        _messages.add({
          'role': 'model',
          'text': '⚠️ **Offline Mode**: I encountered an error while analyzing the reports. Please check your connection or try again later.\n\n_Error: ${e}_'
        });
      });
    }
  }

  Future<void> _sendMessage([String? text]) async {
    final messageText = text ?? _controller.text;
    if (messageText.isEmpty || _chatSession == null) return;

    setState(() {
      if (text == null) _controller.clear();
      _messages.add({'role': 'user', 'text': messageText});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatSession!.sendMessage(Content.user(messageText));
      setState(() {
        _messages.add({'role': 'model', 'text': response.text ?? 'I\'m sorry, I couldn\'t find that information.'});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'model', 'text': '❌ **Error**: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _refreshSession() async {
    setState(() {
      _isLoading = true;
      _messages.add({
        'role': 'model',
        'text': '_Refreshing school database and re-initializing the Strategic Assistant..._'
      });
    });

    try {
      final role = Provider.of<AuthService>(context, listen: false).role ?? 'Principal';
      final service = Provider.of<AIService>(context, listen: false);
      _chatSession = await service.startManagementChatSession(role);
      
      // Verification: Check the current student count from AIService (if we can expose it)
      // For now, we'll rely on the success of the session start.
      
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'model',
          'text': '✅ **Database Synced!** (v2.3) I have re-analyzed all records. How can I help you now?'
        });
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School Database Synchronized Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'model',
          'text': '❌ **Sync Failed**: $e. Using previous context if available.'
        });
      });
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
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: _messages.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120), // Extra bottom padding for floating bar
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
            ),
            if (_isLoading && _messages.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black12),
                ),
              ),
            // Input area is now floating, so we don't put it here in a Column
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildInputArea(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(Icons.auto_awesome, size: 32, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Text(
            "${Provider.of<AuthService>(context, listen: false).role?.capitalize() ?? 'Principal'}'s AI Assistant",
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "How can I help you manage the school today?",
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final role = Provider.of<AuthService>(context, listen: false).role ?? 'Principal';
    final aiLabel = role.toLowerCase() == 'admin' ? 'Admin Assistant' : 'Principal Assistant';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(isUser),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : aiLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (isUser)
                  Text(
                    msg['text'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  )
                else
                  _buildAIResponse(msg['text']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? Colors.grey.shade200 : Colors.black87,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person_outline_rounded : Icons.auto_awesome,
          size: 18,
          color: isUser ? Colors.black54 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildAIResponse(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            h1: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.5),
            h2: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.5),
            h3: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.5),
            p: GoogleFonts.inter(fontSize: 16, color: Colors.black87, height: 1.6),
            listBullet: const TextStyle(fontSize: 16, color: Colors.black54),
            code: GoogleFonts.firaCode(backgroundColor: Colors.grey[100], color: Colors.pink.shade700, fontSize: 14),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
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
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionButton(Icons.copy_rounded, () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
              );
            }),
            const SizedBox(width: 8),
            _buildActionButton(Icons.thumb_up_outlined, () {}),
            const SizedBox(width: 8),
            _buildActionButton(Icons.thumb_down_outlined, () {}),
            const SizedBox(width: 8),
            _buildActionButton(Icons.refresh_rounded, () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildInputArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuickAnalysisChips(),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4],
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.indigo.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.08),
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
                  icon: Icon(Icons.analytics_outlined, color: Colors.indigo.shade300),
                  onPressed: () => _sendMessage("Generate a full school performance report for today."),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 1,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Analyze data or ask for reports...',
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
        ),
      ],
    );
  }

  Widget _buildQuickAnalysisChips() {
    final chips = [
      {'label': 'Sync Data Center', 'icon': Icons.sync, 'action': () => _refreshSession()},
      {'label': 'Syllabus Status', 'icon': Icons.menu_book, 'action': () => _sendMessage("Give me a Syllabus Progress report for all classes.")},
      {'label': 'Attendance Report', 'icon': Icons.calendar_today, 'action': () => _sendMessage("Give me a Attendance Report for today.")},
      {'label': 'Finance Summary', 'icon': Icons.account_balance_wallet, 'action': () => _sendMessage("Give me a Finance Summary for today.")},
      {'label': 'Pending Tasks', 'icon': Icons.assignment_late, 'action': () => _sendMessage("Give me a Pending Tasks report for today.")},
      {'label': 'Student Growth', 'icon': Icons.trending_up, 'action': () => _sendMessage("Give me a Student Growth report for today.")},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: chips.map((chip) {
          final isSync = chip['label'] == 'Sync Data Center';
          return ActionChip(
            avatar: Icon(chip['icon'] as IconData, size: 14, color: isSync ? Colors.green : Colors.indigo),
            label: Text(chip['label'] as String, style: TextStyle(fontSize: 12, color: isSync ? Colors.green.shade700 : Colors.indigo.shade700)),
            onPressed: chip['action'] as VoidCallback,
            backgroundColor: isSync ? Colors.green.shade50 : Colors.indigo.shade50,
            side: BorderSide(color: isSync ? Colors.green.shade100 : Colors.indigo.shade100),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: () => _sendMessage(),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
