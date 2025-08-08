// lib/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pomodoro_record.dart';
import 'package:pomodoro_app/widgets/glass_container.dart';
import 'package:pomodoro_app/widgets/ambient_background.dart';
import 'package:pomodoro_app/utils/stats_utils.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  TimeRange _range = TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final Box<PomodoroRecord> box = Hive.box<PomodoroRecord>('pomodoro_box');

    return AmbientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Productivity Stats'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: 'Clear all history',
              icon: const Icon(Icons.delete_forever_rounded),
              onPressed: _confirmAndClearAll,
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box<PomodoroRecord> box, _) {
            final records = box.values.toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (records.isEmpty)
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 20,
                        child: const Text(
                          'No saved sessions yet.\nComplete a session and save it!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    if (records.isNotEmpty) ...[
                      // Range selector
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final r in TimeRange.values)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(_labelForRange(r)),
                                  selected: _range == r,
                                  onSelected: (_) => setState(() => _range = r),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Today vs Yesterday
                      _TodayComparisonCard(records: records),

                      const SizedBox(height: 12),

                      // Trend chart
                      _TrendChart(range: _range, records: records),

                      const SizedBox(height: 12),

                      // Totals summary
                      _TotalsSummary(records: records),

                      const SizedBox(height: 12),

                      // Recent saves timeline
                      _RecentSaves(
                        records: records.reversed.take(20).toList(),
                        onDelete: _confirmAndDeleteRecord,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _labelForRange(TimeRange r) {
    switch (r) {
      case TimeRange.day:
        return 'Day';
      case TimeRange.week:
        return 'Week';
      case TimeRange.month:
        return 'Month';
      case TimeRange.year:
        return 'Year';
      case TimeRange.all:
        return 'All';
    }
  }
}

class _TodayComparisonCard extends StatelessWidget {
  final List<PomodoroRecord> records;
  const _TodayComparisonCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final cmp = computeTodayComparison(records);
    final tomatoDelta = cmp.tomatoDelta;
    final minuteDelta = cmp.minuteDelta;
    Color tomatoColor = tomatoDelta == 0
        ? Theme.of(context).colorScheme.onSurface
        : tomatoDelta > 0
            ? Colors.green
            : Colors.redAccent;
    Color minuteColor = minuteDelta == 0
        ? Theme.of(context).colorScheme.onSurface
        : minuteDelta > 0
            ? Colors.green
            : Colors.redAccent;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today vs Yesterday', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  context,
                  title: 'Tomatoes',
                  today: cmp.tomatoesToday,
                  yesterday: cmp.tomatoesYesterday,
                  delta: tomatoDelta,
                  color: tomatoColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricTile(
                  context,
                  title: 'Minutes',
                  today: cmp.minutesToday,
                  yesterday: cmp.minutesYesterday,
                  delta: minuteDelta,
                  color: minuteColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(BuildContext context, {required String title, required int today, required int yesterday, required int delta, required Color color}) {
    final arrow = delta == 0 ? Icons.horizontal_rule_rounded : delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final sign = delta > 0 ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('$today', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Icon(arrow, color: color, size: 18),
            const SizedBox(width: 2),
            Text('$sign$delta', style: TextStyle(color: color)),
          ],
        ),
        Text('Yesterday: $yesterday', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final TimeRange range;
  final List<PomodoroRecord> records;
  const _TrendChart({required this.range, required this.records});

  @override
  Widget build(BuildContext context) {
    final points = buildRange(range, records);
    final maxY = (points.isEmpty ? 1 : points.map((e) => e.tomatoes.toDouble()).fold<double>(0, (p, e) => e > p ? e : p)) * 1.4;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trend (${_titleForRange(range)})', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: points.isEmpty
                ? const Center(child: Text('No data yet'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY <= 0 ? 1 : maxY,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            getTitlesWidget: (double v, TitleMeta meta) {
                              final i = v.toInt();
                              if (i < 0 || i >= points.length) return const SizedBox.shrink();
                              final label = labelForBucket(points[i].bucketStart, range);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(label, style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (int i = 0; i < points.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 2,
                            barRods: [
                              BarChartRodData(
                                toY: points[i].tomatoes.toDouble(),
                                rodStackItems: [
                                  BarChartRodStackItem(0, points[i].crushed.toDouble(), Colors.red[200]!),
                                  BarChartRodStackItem(points[i].crushed.toDouble(), (points[i].crushed + points[i].half).toDouble(), Colors.red[400]!),
                                  BarChartRodStackItem((points[i].crushed + points[i].half).toDouble(), points[i].tomatoes.toDouble(), Colors.red[700]!),
                                ],
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          )
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _titleForRange(TimeRange r) {
    switch (r) {
      case TimeRange.day:
        return 'Today';
      case TimeRange.week:
        return 'Last 7 days';
      case TimeRange.month:
        return 'Last 30 days';
      case TimeRange.year:
        return 'Last 12 months';
      case TimeRange.all:
        return 'All time';
    }
  }
}

class _TotalsSummary extends StatelessWidget {
  final List<PomodoroRecord> records;
  const _TotalsSummary({required this.records});

  @override
  Widget build(BuildContext context) {
    int crushed = 0, half = 0, whole = 0;
    for (final r in records) {
      crushed += r.crushedTomatoes;
      half += r.halfTomatoes;
      whole += r.wholeTomatoes;
    }
    final totalTomatoes = crushed + half + whole;
    final totalMinutes = (crushed * 5) + (half * 12) + (whole * 25);
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _pill(context, label: 'Crushed', value: crushed, color: Colors.red[200]!),
          const SizedBox(width: 8),
          _pill(context, label: 'Half', value: half, color: Colors.red[400]!),
          const SizedBox(width: 8),
          _pill(context, label: 'Whole', value: whole, color: Colors.red[700]!),
          const Spacer(),
          Text('$totalTomatoes tomatoes · '),
          Text('${hours}h ${mins}m', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, {required String label, required int value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: $value'),
        ],
      ),
    );
  }
}

class _RecentSaves extends StatelessWidget {
  final List<PomodoroRecord> records; // newest first
  final void Function(PomodoroRecord) onDelete;
  const _RecentSaves({required this.records, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Saves', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final r in records)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(_formatWhen(r.date)),
                  const Spacer(),
                  _dot(Colors.red[200]!), Text(' ${r.crushedTomatoes}'),
                  const SizedBox(width: 6),
                  _dot(Colors.red[400]!), Text(' ${r.halfTomatoes}'),
                  const SizedBox(width: 6),
                  _dot(Colors.red[700]!), Text(' ${r.wholeTomatoes}'),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Delete this record',
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: () => onDelete(r),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatWhen(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _dot(Color c) => Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

extension on _StatsScreenState {
  Future<void> _confirmAndDeleteRecord(PomodoroRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text('This will permanently remove the selected session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await r.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete record.')));
        }
      }
    }
  }

  Future<void> _confirmAndClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This will permanently delete all saved sessions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete all')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final box = Hive.box<PomodoroRecord>('pomodoro_box');
        await box.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All records deleted.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to clear history.')));
        }
      }
    }
  }
}