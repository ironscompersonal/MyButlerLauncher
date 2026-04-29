import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/style_constants.dart';
import 'glass_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';

class AIInsightCard extends ConsumerWidget {
  final VoidCallback? onAction;

  const AIInsightCard({
    super.key,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiInsight = ref.watch(aiInsightProvider);
    final theme = Theme.of(context);
    
    return aiInsight.when(
      data: (text) => _buildCard(context, text, theme),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => _buildCard(context, '主人、情報の整理中にエラーが発生いたしました。\n詳細: $err', theme),
    );
  }

  Widget _buildCard(BuildContext context, String text, ThemeData theme) {
    final lines = text.split('\n');
    
    Color accentColor = StyleConstants.statusLineNormal;
    bool isUrgent = text.contains('緊急') || text.contains('重要');
    bool isWarning = text.contains('警告') || text.contains('注意');
    
    if (isUrgent) {
      accentColor = StyleConstants.statusLineAlert;
    } else if (isWarning) {
      accentColor = Colors.orangeAccent;
    }

    return GlassCard(
      accentColor: accentColor,
      isVibrant: isUrgent || isWarning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.sparkles, size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Text(
                'MY AI BUTLER',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              if (onAction != null)
                IconButton(
                  onPressed: onAction,
                  tooltip: '執事に詳しく聞く',
                  icon: const Icon(LucideIcons.messageSquare, size: 22, color: Colors.white54),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...lines.map((line) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) return const SizedBox(height: 8);
            if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRichText(
                        trimmed.substring(1).trim(),
                        theme.textTheme.bodyMedium?.copyWith(
                          color: (isUrgent || isWarning) ? Colors.white : Colors.white70,
                        ) ?? const TextStyle(),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRichText(
                trimmed,
                theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400, fontSize: 18) ?? const TextStyle(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRichText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final Match match in regExp.allMatches(text)) {
      // マッチする前のテキストを追加
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start), style: baseStyle));
      }
      // 太字部分を追加
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
      ));
      lastIndex = match.end;
    }

    // 残りのテキストを追加
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    if (spans.isEmpty) {
      return Text(text, style: baseStyle);
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
