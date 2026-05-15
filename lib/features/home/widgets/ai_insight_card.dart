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
    final cardState = ref.watch(butlerCardProvider);
    final theme = Theme.of(context);

    // 初期化をスケジュール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cardState.content.isEmpty) {
        ref.read(butlerCardProvider.notifier).initialize();
      }
    });

    return _buildCard(context, cardState, theme, ref);
  }

  Widget _buildCard(BuildContext context, ButlerCardState state, ThemeData theme, WidgetRef ref) {
    final isListening = state.mode == ButlerCardMode.listening;
    final text = isListening 
        ? (state.lastRecognition?.isEmpty ?? true ? 'お聞きしております...' : state.lastRecognition!)
        : state.content;
    
    final lines = text.split('\n');
    
    Color accentColor = StyleConstants.statusLineNormal;
    if (isListening) {
      accentColor = Colors.cyanAccent;
    } else if (state.mode == ButlerCardMode.thinking) {
      accentColor = Colors.purpleAccent;
    }

    return GlassCard(
      accentColor: accentColor,
      isVibrant: isListening || state.mode == ButlerCardMode.thinking,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // アニメーションを想起させるマイクアイコン
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isListening ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                  boxShadow: isListening ? [
                    BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                  ] : [],
                ),
                child: Icon(
                  isListening ? LucideIcons.mic : LucideIcons.sparkles, 
                  size: 20, 
                  color: accentColor
                ),
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
              if (state.mode == ButlerCardMode.chat)
                IconButton(
                  onPressed: () => ref.read(butlerCardProvider.notifier).resetToInsight(),
                  tooltip: '報告に戻る',
                  icon: const Icon(LucideIcons.rotateCcw, size: 20, color: Colors.white54),
                ),
              IconButton(
                onPressed: () {
                  if (state.mode == ButlerCardMode.listening) {
                    ref.read(butlerCardProvider.notifier).stopListening();
                  } else {
                    ref.read(butlerCardProvider.notifier).startListening();
                  }
                },
                tooltip: '執事に話しかける',
                icon: Icon(
                  state.mode == ButlerCardMode.listening ? LucideIcons.micOff : LucideIcons.mic, 
                  size: 22, 
                  color: state.mode == ButlerCardMode.listening ? Colors.redAccent : Colors.white70
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.mode == ButlerCardMode.thinking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            ...lines.map((line) {
              final trimmed = line.trim();
              if (trimmed.isEmpty) return const SizedBox(height: 8);
              
              // 特殊な行（箇条書き）の処理
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
                          theme.textTheme.bodyMedium?.copyWith(color: Colors.white70) ?? const TextStyle(),
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
                  theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: state.mode == ButlerCardMode.chat ? FontWeight.w500 : FontWeight.w400,
                    fontSize: state.mode == ButlerCardMode.chat ? 19 : 18,
                    color: state.mode == ButlerCardMode.listening ? Colors.white : Colors.white.withOpacity(0.9),
                  ) ?? const TextStyle(),
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
