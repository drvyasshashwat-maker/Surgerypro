import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;

  final List<Map<String, String>> _history = [];

  final _suggestions = [
    'What are the branches of the portal vein?',
    'Explain Hartmann\'s procedure',
    'MRCS Part A key topics in hepatobiliary surgery',
    'Management of acute appendicitis in NHS',
    'FRCS viva: complications of thyroidectomy',
  ];

  Future<void> _send([String? text]) async {
    final msg = (text ?? _controller.text).trim();
    if (msg.isEmpty || _loading) return;
    _controller.clear();

    setState(() {
      _messages.add(_Message(msg, true));
      _loading = true;
    });
    _scroll();

    try {
      final reply = await GeminiService.chat(msg, _history);
      _history.add({'role': 'user', 'text': msg});
      _history.add({'role': 'model', 'text': reply});
      setState(() {
        _messages.add(_Message(reply, false));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message('Error: ${e.toString()}\n\nMake sure your Gemini API key is set in Settings.', false));
        _loading = false;
      });
    }
    _scroll();
  }

  void _scroll() {
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
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Row(children: [
          CircleAvatar(backgroundColor: AppTheme.accent, radius: 14,
            child: Icon(Icons.psychology_rounded, color: Colors.white, size: 16)),
          SizedBox(width: 10),
          Text('SurgeryPro AI'),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => setState(() { _messages.clear(); _history.clear(); }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
              ? _buildSuggestions()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) return _TypingIndicator();
                    return _MessageBubble(message: _messages[i]);
                  },
                ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.psychology_rounded, size: 56, color: AppTheme.accent),
        const SizedBox(height: 12),
        const Text('SurgeryPro AI', style: TextStyle(
          color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 4),
        const Text('Expert surgical knowledge for MRCS, FRCS & NHS',
          style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ..._suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _send(s),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E3A5F)),
              ),
              child: Text(s, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            ),
          ),
        )),
      ],
    ),
  );

  Widget _buildInput() => Container(
    padding: EdgeInsets.only(
      left: 16, right: 16, top: 12,
      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
    ),
    decoration: const BoxDecoration(
      color: AppTheme.cardBg,
      border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
    ),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: _controller,
          maxLines: 4,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Ask about surgery, anatomy, procedures...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _send(),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: _loading ? null : () => _send(),
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _loading ? AppTheme.textSecondary : AppTheme.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _loading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
            color: Colors.white, size: 20,
          ),
        ),
      ),
    ]),
  );
}

class _Message {
  final String text;
  final bool isUser;
  _Message(this.text, this.isUser);
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? AppTheme.accent : AppTheme.cardBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser ? null : Border.all(color: const Color(0xFF1E3A5F)),
        ),
        child: Text(message.text, style: TextStyle(
          color: message.isUser ? Colors.white : AppTheme.textPrimary,
          fontSize: 15, height: 1.5,
        )),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
        SizedBox(width: 10),
        Text('Thinking...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    ),
  );
}
