import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';
import '../providers/home_providers.dart';
import '../../../core/constants/style_constants.dart';

enum HealthMetric {
  weight('Weight', 'kg', 'weight'),
  bodyFat('Body Fat', '%', 'body_fat'),
  muscle('Muscle', 'kg', 'lean_mass'),
  bone('Bone', 'kg', 'body_water');

  final String label;
  final String unit;
  final String key;
  const HealthMetric(this.label, this.unit, this.key);
}

class HealthCard extends ConsumerStatefulWidget {
  const HealthCard({super.key});

  @override
  ConsumerState<HealthCard> createState() => _HealthCardState();
}

class _HealthCardState extends ConsumerState<HealthCard> {
  HealthMetric _selectedMetric = HealthMetric.weight;

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(healthDataProvider);
    final weeklyAsync = ref.watch(weeklyHealthDataProvider);
    final theme = Theme.of(context);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(LucideIcons.activity, color: StyleConstants.themeAccent, size: 20),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'HEALTH STATUS',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rolling 7 Days',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 24),
            healthAsync.when(
              data: (data) {
                if (data.isEmpty) return const _NoDataWidget();
                return Column(
                  children: [
                    _buildMainStats(data),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    _buildBodyComposition(data),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.white30)),
            ),
            const SizedBox(height: 32),
            // Metric Selection Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: HealthMetric.values.map((metric) {
                  final isSelected = _selectedMetric == metric;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMetric = metric),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? StyleConstants.themeAccent : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
                      ),
                      child: Text(
                        metric.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white38,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            weeklyAsync.when(
              data: (weeklyData) {
                if (weeklyData.isEmpty) return const SizedBox(height: 150, child: Center(child: Text('No trend data')));
                return Column(
                  children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _LineChartPainter(
                          data: weeklyData,
                          metric: _selectedMetric,
                          accentColor: StyleConstants.themeAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        if (weeklyData.length <= i) return const SizedBox();
                        final date = weeklyData[i]['date'] as DateTime;
                        return Text(
                          DateFormat('E').format(date).toUpperCase()[0],
                          style: const TextStyle(color: Colors.white24, fontSize: 10),
                        );
                      }),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
              error: (err, _) => const SizedBox(height: 150, child: Center(child: Text('Trend error'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          icon: LucideIcons.footprints,
          label: 'Steps',
          value: data['steps'].toString(),
          unit: '',
        ),
        _StatItem(
          icon: LucideIcons.moon,
          label: 'Sleep',
          value: _formatMinutes(data['sleep_minutes']),
          unit: '',
        ),
        _StatItem(
          icon: LucideIcons.heart,
          label: 'Heart',
          value: data['avg_heart_rate'].toString(),
          unit: 'bpm',
        ),
      ],
    );
  }

  Widget _buildBodyComposition(Map<String, dynamic> data) {
    return Wrap(
      spacing: 20,
      runSpacing: 16,
      children: [
        _BodyCompItem(label: 'Weight', value: data['weight']?.toStringAsFixed(1) ?? '--', unit: 'kg'),
        _BodyCompItem(label: 'Body Fat', value: data['body_fat']?.toStringAsFixed(1) ?? '--', unit: '%'),
        _BodyCompItem(label: 'Muscle', value: data['lean_mass']?.toStringAsFixed(1) ?? '--', unit: 'kg'),
        _BodyCompItem(label: 'Bone', value: data['body_water']?.toStringAsFixed(1) ?? '--', unit: 'kg'),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes == 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final HealthMetric metric;
  final Color accentColor;

  _LineChartPainter({required this.data, required this.metric, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final values = data.map((e) => (e[metric.key] as double? ?? 0.0)).toList();
    final nonZeroValues = values.where((v) => v > 0).toList();
    
    double minVal = nonZeroValues.isEmpty ? 0 : nonZeroValues.reduce((a, b) => a < b ? a : b);
    double maxVal = nonZeroValues.isEmpty ? 100 : nonZeroValues.reduce((a, b) => a > b ? a : b);
    
    // 余白を持たせる
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    } else {
      final diff = maxVal - minVal;
      maxVal += diff * 0.2;
      minVal -= diff * 0.2;
    }
    if (minVal < 0) minVal = 0;

    final double width = size.width;
    final double height = size.height;
    final double stepX = width / (data.length - 1);

    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final val = values[i];
      if (val == 0) continue; // データなし
      final x = i * stepX;
      final y = height - ((val - minVal) / (maxVal - minVal) * height);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // 背景グリッド（簡易）
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = i * (height / 3);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // グラデーション（塗りつぶし）
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, height);
      for (var p in points) {
        path.lineTo(p.dx, p.dy);
      }
      path.lineTo(points.last.dx, height);
      path.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor.withOpacity(0.3), accentColor.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, width, height));
      canvas.drawPath(path, fillPaint);
    }

    // ライン
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // 曲線にする場合はcubicToを使うが、今回はシンプルにlineTo
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // ポイントのドット
    final dotPaint = Paint()..color = Colors.white;
    final dotOutlinePaint = Paint()..color = accentColor..strokeWidth = 2..style = PaintingStyle.stroke;
    
    for (var p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotOutlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.metric != metric;
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _StatItem({required this.icon, required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        if (unit.isNotEmpty) Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

class _BodyCompItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _BodyCompItem({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(color: Colors.white24, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoDataWidget extends StatelessWidget {
  const _NoDataWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Health Connectデータ未取得\n設定から権限を許可してください',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ),
    );
  }
}
