import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/gemini_service.dart';
import '../../core/prompts/system_prompts.dart';

// ============================================================
//  AI CHAT SCREEN
//  Full-featured chat with streaming, module selector,
//  history, copy, and bilingual support.
// ============================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  String _streamingBuffer = '';
  String _currentModule = 'general';
  String? _uploadedPdfText;
  String _uploadedFileName = '';

  // Module definitions — switch to change AI behavior completely
  final Map<String, Map<String, dynamic>> _modules = {
    'general': {
      'label': 'General',
      'icon': Icons.auto_awesome,
      'color': const Color(0xFF6366F1),
      'prompt': () => SystemPrompts.generalMode(),
    },
    'study': {
      'label': 'Study',
      'icon': Icons.menu_book,
      'color': const Color(0xFF059669),
      'prompt': () => SystemPrompts.studyMode(),
    },
    'career': {
      'label': 'Career',
      'icon': Icons.work,
      'color': const Color(0xFFD97706),
      'prompt': () => SystemPrompts.careerMode(),
    },
    'math': {
      'label': 'Math',
      'icon': Icons.calculate,
      'color': const Color(0xFFDC2626),
      'prompt': () => SystemPrompts.mathMode(),
    },
    'code': {
      'label': 'Code',
      'icon': Icons.code,
      'color': const Color(0xFF0891B2),
      'prompt': () => SystemPrompts.codingMode(),
    },
    'planner': {
      'label': 'Planner',
      'icon': Icons.calendar_today,
      'color': const Color(0xFF7C3AED),
      'prompt': () => SystemPrompts.plannerMode(),
    },
  };

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(
      ChatMessage(
        role: 'assistant',
        content:
            'Assalam o Alaikum! 👋\n\nMain ZehnAI hoon — aapka personal AI assistant.\n\n'
            'Main aapki madad kar sakta hoon:\n'
            '📚 Concepts samjhane mein\n'
            '💼 Resume aur interview prep mein\n'
            '🧮 Math problems solve karne mein\n'
            '💻 Coding mein\n'
            '📅 Daily planning mein\n\n'
            'Koi bhi sawaal puchein — English ya Urdu mein!',
        timestamp: DateTime.now(),
      ),
    );
  }

  String get _currentSystemPrompt {
    final promptFn = _modules[_currentModule]!['prompt'] as String Function();
    return promptFn();
  }

  List<Map<String, dynamic>> get _historyForAPI {
    return _messages
        .where((m) => m.role != 'system')
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(role: 'user', content: text, timestamp: DateTime.now()),
      );
      _isLoading = true;
      _streamingBuffer = '';
      _inputController.clear();
    });

    _scrollToBottom();

    // Add empty assistant message that will be filled by stream
    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content: '',
          timestamp: DateTime.now(),
          isStreaming: true,
        ),
      );
    });

    // Stream the response
    try {
      await for (final chunk in GeminiService.streamMessage(
        systemPrompt: _currentSystemPrompt,
        conversationHistory: _historyForAPI.take(_historyForAPI.length - 1).toList(),
        userMessage: text,
        pdfText: _uploadedPdfText,
      )) {
        setState(() {
          _streamingBuffer += chunk;
          _messages.last.content = _streamingBuffer;
        });
        _scrollToBottom();
      }
    } finally {
      setState(() {
        _isLoading = false;
        if (_messages.last.isStreaming) {
          _messages.last.isStreaming = false;
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _uploadedPdfText = null;
      _uploadedFileName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // MTT dark navy
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ZehnAI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _modules[_currentModule]!['label'] + ' Mode',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF94A3B8)),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Module selector
          _buildModuleSelector(),

          // PDF upload banner
          if (_uploadedFileName.isNotEmpty) _buildPdfBanner(),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index]),
            ),
          ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildModuleSelector() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF162032),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _modules.entries.map((entry) {
          final isSelected = _currentModule == entry.key;
          final color = entry.value['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _currentModule = entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFF2D3748),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.value['icon'] as IconData,
                    size: 14,
                    color: isSelected ? color : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    entry.value['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPdfBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF059669)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _uploadedFileName,
              style: const TextStyle(color: Color(0xFF059669), fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _uploadedPdfText = _uploadedFileName = ''),
            child: const Icon(Icons.close, size: 16, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF8C00).withOpacity(0.3),
                ),
              ),
              child: const Center(
                child: Text('Z', style: TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFFFF8C00).withOpacity(0.12)
                      : const Color(0xFF162032),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: Border.all(
                    color: isUser
                        ? const Color(0xFFFF8C00).withOpacity(0.25)
                        : const Color(0xFF1E293B),
                  ),
                ),
                child: msg.isStreaming && msg.content.isEmpty
                    ? _buildTypingIndicator()
                    : SelectableText(
                        msg.content,
                        style: TextStyle(
                          color: isUser
                              ? const Color(0xFFFFF7ED)
                              : const Color(0xFFE2E8F0),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + i * 200),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF475569),
                  const Color(0xFFFF8C00),
                  value,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2D3748)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Apna sawaal likhe... (English or Urdu)',
                        hintStyle:
                            TextStyle(color: Color(0xFF475569), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isLoading
                    ? const Color(0xFF475569)
                    : const Color(0xFFFF8C00),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ----------------------------------------------------------
//  CHAT MESSAGE MODEL
// ----------------------------------------------------------
class ChatMessage {
  final String role;
  String content;
  final DateTime timestamp;
  bool isStreaming;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });
}
