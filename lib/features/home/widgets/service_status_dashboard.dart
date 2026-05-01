import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import '../providers/home_providers.dart';

class ServiceStatusDashboard extends ConsumerWidget {
  const ServiceStatusDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(serviceStatusProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM STATUS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...statuses.entries.map((entry) {
            Widget? action;
            if (entry.key == 'Health' && entry.value == ServiceStatus.warning) {
              action = TextButton(
                onPressed: () => ref.read(healthServiceProvider).openHealthConnectStore(),
                child: const Text('INSTALL', style: TextStyle(color: Colors.cyanAccent, fontSize: 9)),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _StatusItem(
                label: entry.key,
                status: entry.value,
                action: action,
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // 各プロバイダを強制的にリフレッシュ
                ref.invalidate(googleDataSummaryProvider);
                ref.invalidate(weatherProvider);
                ref.invalidate(transitProvider);
                ref.invalidate(aiInsightProvider);
                ref.invalidate(healthStatusProvider);
                ref.invalidate(healthDataProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('情報を更新しています...', style: TextStyle(color: Colors.white))),
                );
              },
              icon: const Icon(Icons.sync, size: 16, color: Colors.white54),
              label: const Text('FORCE RE-SYNC', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    ).asGlass(
      blurX: 15,
      blurY: 15,
      clipBorderRadius: BorderRadius.circular(24),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final ServiceStatus status;
  final Widget? action;

  const _StatusItem({
    required this.label,
    required this.status,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    bool isBlinking = false;

    switch (status) {
      case ServiceStatus.success:
        statusColor = const Color(0xFF00FF88);
        statusText = 'CONNECTED';
        break;
      case ServiceStatus.error:
        statusColor = const Color(0xFFFF3366);
        statusText = 'ERROR';
        break;
      case ServiceStatus.loading:
        statusColor = Colors.amber;
        statusText = 'SYNCING';
        isBlinking = true;
        break;
      case ServiceStatus.idle:
        statusColor = Colors.white24;
        statusText = 'STANDBY';
        break;
      case ServiceStatus.warning:
        statusColor = Colors.orange;
        statusText = 'NOT INSTALLED';
        break;
    }

    return Row(
      children: [
        _LedIndicator(color: statusColor, isBlinking: isBlinking),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor.withOpacity(0.8),
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 8),
          action!,
        ],
      ],
    );
  }
}

class _LedIndicator extends StatefulWidget {
  final Color color;
  final bool isBlinking;

  const _LedIndicator({
    required this.color,
    this.isBlinking = false,
  });

  @override
  State<_LedIndicator> createState() => _LedIndicatorState();
}

class _LedIndicatorState extends State<_LedIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = widget.isBlinking ? (0.3 + 0.7 * _controller.value) : 1.0;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(opacity),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * opacity),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
