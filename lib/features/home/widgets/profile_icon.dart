import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/home_providers.dart';
import '../../../core/services/notification_service.dart';
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
            _buildActionTile(Icons.bug_report, 'デバッグログを表示', () => _showDebugLog(context, ref)),
            const Divider(height: 20, color: Colors.white10),
            if (user == null)
              _buildActionTile(Icons.login, 'Googleでログイン', () async {
                try {
                  // 一旦サインアウトしてからサインインを試みる（キャッシュクリア）
                  await googleSignIn.signOut();
                  final account = await googleSignIn.signIn();
                  if (account != null) {
                    ref.read(googleUserProvider.notifier).state = account;
                    if (context.mounted) Navigator.pop(context);
                  } else {
                    debugPrint('Login was canceled or returned null');
                  }
                } catch (e) {
                  debugPrint('Login failed error: $e');
                  final actualSignature = await ref.read(notificationServiceProvider).getAppSignature();
                  
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('ログイン失敗', style: TextStyle(color: Colors.white)),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('エラー詳細: $e', style: const TextStyle(color: Colors.redAccent)),
                              const SizedBox(height: 16),
                              const Text('【重要】登録すべき SHA-1 指紋:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              SelectableText(
                                actualSignature,
                                style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '※上記をコピーして、Firebase Console の「プロジェクトの設定」>「com.mybutler.launcher_app」の SHA-1 欄に登録し、保存してください。',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              })
            else
              _buildActionTile(Icons.logout, 'ログアウト', () async {
                try {
                  await googleSignIn.disconnect();
                } catch (e) {
                  await googleSignIn.signOut();
                }
                ref.read(googleUserProvider.notifier).state = null;
                Navigator.pop(context);
              }),
              _buildActionTile(Icons.note_alt_outlined, 'ご主人様の覚書', () async {
                Navigator.pop(context); // メニューを閉じる
                final currentProfile = ref.read(personalProfileProvider);
                final newProfile = await _showPersonalProfileDialog(context, currentProfile);
                if (newProfile != null) {
                  await ref.read(personalProfileProvider.notifier).updateProfile(newProfile);
                }
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

  void _showDebugLog(BuildContext context, WidgetRef ref) {
    final errorLog = ref.read(googleApiErrorProvider);
    final user = ref.read(googleUserProvider);
    final googleData = ref.read(googleDataSummaryProvider);
    
    String statusInfo = '【システム状況】\n';
    statusInfo += 'ログイン状態: ${user != null ? "ログイン中 (${user.email})" : "未ログイン"}\n';
    statusInfo += 'データ取得状況: ${googleData.hasValue ? "取得済み" : "未取得"}\n\n';
    statusInfo += '【エラー・ログ】\n';
    statusInfo += errorLog.isEmpty ? '現在エラーは記録されていません。' : errorLog;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('システムデバッグログ', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: SelectableText(
            statusInfo,
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
        ],
      ),
    );
  }

  Future<String?> _showPersonalProfileDialog(BuildContext context, String currentProfile) async {
    final controller = TextEditingController(text: currentProfile);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('ご主人様の覚書', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '執事に覚えておいてほしい、ご主人様の好みや習慣、個人的な情報を入力してください。',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 8,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '例: 辛いものが好き。誕生日は6月1日。朝はコーヒー派。',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
