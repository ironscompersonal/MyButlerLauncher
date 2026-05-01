import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'glass_card.dart';
import '../../../core/constants/style_constants.dart';
import '../providers/home_providers.dart';
import '../../../core/services/chat_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // 最初のメッセージを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'butler',
            'text': 'ご主人様、何でしょうか？'
          });
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final chatService = ref.read(chatServiceProvider);
    if (text.isEmpty || chatService == null) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isThinking = true;
    });

    try {
      final response = await chatService.sendMessage(text);
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

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              _sendMessage();
            }
          }),
          localeId: 'ja_JP',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
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
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isListening ? Colors.redAccent : Colors.white.withOpacity(0.1),
                  child: IconButton(
                    icon: Icon(_isListening ? LucideIcons.mic : LucideIcons.micOff, 
                               color: _isListening ? Colors.white : Colors.white54, size: 20),
                    onPressed: _listen,
                  ),
                ),
                const SizedBox(width: 8),
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
