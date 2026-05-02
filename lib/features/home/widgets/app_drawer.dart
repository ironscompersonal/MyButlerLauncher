import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import 'glass_card.dart';
import '../../../core/constants/style_constants.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);
    final usageStats = ref.watch(appUsageProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text(
            'APPLICATIONS',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: appsAsync.when(
              data: (apps) {
                // AIによるアレンジ（利用頻度順にソート、同数の場合は名前順）
                final sortedApps = List<Map<String, dynamic>>.from(apps)
                  ..sort((a, b) {
                    final countA = usageStats[a['packageName']] ?? 0;
                    final countB = usageStats[b['packageName']] ?? 0;
                    if (countA != countB) {
                      return countB.compareTo(countA); // 降順
                    }
                    return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
                  });
                
                final displayApps = _isExpanded ? sortedApps : sortedApps.take(16).toList();
                final hasMore = sortedApps.length > 16;

                return Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: displayApps.length,
                        itemBuilder: (context, index) {
                          final app = displayApps[index];
                          final packageName = app['packageName'] as String;
                          
                          return GestureDetector(
                            onTap: () {
                              // 起動時に利用頻度をカウントアップ
                              ref.read(appUsageProvider.notifier).recordLaunch(packageName);
                              ref.read(appLauncherServiceProvider).launchApp(packageName);
                              Navigator.pop(context);
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Consumer(
                                    builder: (context, ref, child) {
                                      final iconAsync = ref.watch(appIconProvider(packageName));
                                      return iconAsync.when(
                                        data: (iconData) => iconData != null
                                            ? Image.memory(
                                                iconData,
                                                width: 45,
                                                height: 45,
                                                fit: BoxFit.contain,
                                              )
                                            : const Icon(Icons.apps, color: Colors.white70, size: 45),
                                        loading: () => const SizedBox(
                                          width: 45,
                                          height: 45,
                                          child: Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                                            ),
                                          ),
                                        ),
                                        error: (_, __) => const Icon(Icons.error_outline, color: Colors.white30, size: 45),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  app['name'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasMore && !_isExpanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: TextButton.icon(
                          onPressed: () => setState(() => _isExpanded = true),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                          label: Text(
                            'SHOW ALL (${sortedApps.length - 16} MORE)',
                            style: const TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('アプリ一覧の取得に失敗しました: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
