import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'glass_card.dart';
import '../../../core/constants/style_constants.dart';
import '../providers/home_providers.dart';
import '../../../core/services/chat_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class ChatOverlay extends ConsumerStatefulWidget {
  const ChatOverlay({super.key});

  @override
  ConsumerState<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends ConsumerState<ChatOverlay> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isThinking = false;
  ChatService? _chatService;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    final apiKey = ref.read(aiApiKeyProvider);
    if (apiKey.isNotEmpty) {
      _chatService = ChatService(apiKey, []);
      
      setState(() {
        _messages.add({
          'role': 'butler',
          'text': 'ご主人様、何でしょうか？'
        });
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatService == null) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isThinking = true;
    });

    try {
      final response = await _chatService!.sendMessage(text);
      setState(() {
        _messages.add({'role': 'butler', 'text': response});
        _isThinking = false;
      });
    } catch (e) {
      debugPrint('Chat Error: $e');
      setState(() {
        _messages.add({
          'role': 'butler', 
          'text': '申し訳ございません。通信エラーが発生いたしました。\n理由: $e'
        });
        _isThinking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isButler = msg['role'] == 'butler';
                return Align(
                  alignment: isButler ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isButler ? Colors.white.withOpacity(0.1) : StyleConstants.themeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isThinking)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('執事が考え中...', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '執事にメッセージを送る',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: StyleConstants.themeAccent,
                  child: IconButton(
                    icon: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
