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
              // タイトルをFlexibleに包み、ボタンエリアを確保
              Flexible(
                child: Text(
                  'MY AI BUTLER',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // ボタンエリア：InkWellを使用してタイトに配置
              if (state.mode == ButlerCardMode.chat)
                _buildCustomButton(
                  icon: LucideIcons.rotateCcw,
                  onTap: () => ref.read(butlerCardProvider.notifier).resetToInsight(),
                  color: Colors.white54,
                  size: 18,
                ),
              _buildCustomButton(
                icon: state.mode == ButlerCardMode.listening ? LucideIcons.micOff : LucideIcons.mic,
                onTap: () {
                  if (state.mode == ButlerCardMode.listening) {
                    ref.read(butlerCardProvider.notifier).stopListening();
                  } else {
                    ref.read(butlerCardProvider.notifier).startListening();
                  }
                },
                color: state.mode == ButlerCardMode.listening ? Colors.redAccent : Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isListening)
            _buildVisualizer(state.amplitude),
          const SizedBox(height: 10),
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

  Widget _buildVisualizer(double amplitude) {
    double normalized = (amplitude + 60) / 60;
    if (normalized < 0) normalized = 0;
    if (normalized > 1) normalized = 1;

    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.cyanAccent.withOpacity(0.0), Colors.cyanAccent.withOpacity(0.05), Colors.cyanAccent.withOpacity(0.0)],
        ),
      ),
      child: CustomPaint(
        painter: WavePainter(normalized),
      ),
    );
  }

  Widget _buildCustomButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required double size,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double amplitude;
  WavePainter(this.amplitude);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3); // ネオンの発光効果

    final centerY = size.height / 2;
    final width = size.width;
    const count = 40;
    final spacing = width / count;

    for (int i = 0; i < count; i++) {
      double distFromCenter = (i - count / 2).abs() / (count / 2);
      // 中央ほど高く、端ほど低く。amplitudeで全体を揺らす
      double heightFactor = (1.0 - distFromCenter * 0.7) * (0.1 + 0.9 * amplitude);
      
      // サイン波のような揺らぎを追加
      double wave = 0.8 + 0.2 * (distFromCenter * 3.14).hashCode.toDouble().remainder(1.0);
      double h = (size.height * 0.9) * heightFactor * wave;
      if (h < 2) h = 2;

      double x = i * spacing + spacing / 2;
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}
