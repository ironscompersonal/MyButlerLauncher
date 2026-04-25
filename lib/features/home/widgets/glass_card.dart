import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/style_constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final bool isVibrant;

  const GlassCard({
    super.key,
    required this.child,
    this.accentColor,
    this.isVibrant = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(StyleConstants.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: StyleConstants.glassBlur, sigmaY: StyleConstants.glassBlur),
        child: Container(
          decoration: BoxDecoration(
            color: StyleConstants.glassBackground,
            borderRadius: BorderRadius.circular(StyleConstants.cardRadius),
            border: Border.all(color: StyleConstants.glassBorder),
          ),
          child: Stack(
            children: [
              if (accentColor != null)
                Positioned(
                  left: 0,
                  top: 20,
                  bottom: 20,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                      boxShadow: isVibrant ? [
                        BoxShadow(color: accentColor!.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                      ] : null,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(StyleConstants.cardPadding),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
