import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/home_providers.dart';

class ProfileIconWidget extends ConsumerWidget {
  const ProfileIconWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(googleUserProvider);
    
    return GestureDetector(
      onTap: () => _showProfileModal(context, ref),
      child: Container(
        margin: const EdgeInsets.only(top: 10, right: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white10,
          backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
          child: user?.photoUrl == null ? const Icon(Icons.person, color: Colors.white60) : null,
        ),
      ),
    );
  }

  void _showProfileModal(BuildContext context, WidgetRef ref) {
    final user = ref.read(googleUserProvider);
    final apiKey = ref.read(aiApiKeyProvider);
    final googleSignIn = ref.read(googleSignInProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white30) : null,
            ),
            const SizedBox(height: 16),
            Text(user?.displayName ?? '未ログイン', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '---', style: const TextStyle(color: Colors.white54)),
            const Divider(height: 40, color: Colors.white12),
            
            _buildActionTile(Icons.api, 'Gemini APIキーを設定', () async {
              final result = await _showApiKeyDialog(context, apiKey);
              if (result != null) {
                await ref.read(aiApiKeyProvider.notifier).setKey(result);
              }
            }),
            _buildActionTile(Icons.help_outline, 'APIキーの入手方法', () => _launchURL('https://aistudio.google.com/app/apikey')),
            const Divider(height: 20, color: Colors.white10),
            if (user == null)
              _buildActionTile(Icons.login, 'Googleでログイン', () async {
                try {
                  // 一旦サインアウトしてからサインインを試みる（キャッシュクリア）
                  await googleSignIn.signOut();
                  final account = await googleSignIn.signIn();
                  if (account != null) {
                    ref.read(googleUserProvider.notifier).state = account;
                  }
                } catch (e) {
                  debugPrint('Login failed error: $e');
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('ログイン失敗'),
                        content: Text('エラー詳細: $e\n\n※AndroidでGoogleログインを行うには、Google Cloud Consoleでこのアプリのパッケージ名(com.example.ai_butler_launcher)とSHA-1証明書を登録する必要があります。'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                  }
                }
                if (context.mounted) Navigator.pop(context);
              })
            else
              _buildActionTile(Icons.logout, 'ログアウト', () async {
                await googleSignIn.signOut();
                ref.read(googleUserProvider.notifier).state = null;
                Navigator.pop(context);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Future<String?> _showApiKeyDialog(BuildContext context, String currentKey) async {
    final controller = TextEditingController(text: currentKey);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('APIキーの設定', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'ここにAPIキーを入力', hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('保存')),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
