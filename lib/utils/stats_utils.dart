// lib/utils/stats_utils.dart

import 'package:pomodoro_app/models/pomodoro_record.dart';

enum TimeRange { day, week, month, year, all }

class AggregatedPoint {
  final DateTime bucketStart; // normalized start (day or month)
  int crushed;
  int half;
  int whole;

  AggregatedPoint({
    required this.bucketStart,
    this.crushed = 0,
    this.half = 0,
    this.whole = 0,
  });

  int get tomatoes => crushed + half + whole;
  int get minutes => (crushed * 5) + (half * 12) + (whole * 25);
}

int recordTomatoes(PomodoroRecord r) => r.crushedTomatoes + r.halfTomatoes + r.wholeTomatoes;
int recordMinutes(PomodoroRecord r) => (r.crushedTomatoes * 5) + (r.halfTomatoes * 12) + (r.wholeTomatoes * 25);

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);

DateTime startOfYesterday(DateTime now) => startOfDay(now).subtract(const Duration(days: 1));

/// Returns a list of normalized daily buckets in [start..end] inclusive.
List<DateTime> _daysInRange(DateTime start, DateTime end) {
  final res = <DateTime>[];
  var cur = startOfDay(start);
  final last = startOfDay(end);
  while (!cur.isAfter(last)) {
    res.add(cur);
    cur = cur.add(const Duration(days: 1));
  }
  return res;
}

/// Returns a list of month starts from [startMonth] to [endMonth] inclusive.
List<DateTime> _monthsInRange(DateTime startMonth, DateTime endMonth) {
  final res = <DateTime>[];
  var cur = startOfMonth(startMonth);
  final last = startOfMonth(endMonth);
  while (!cur.isAfter(last)) {
    res.add(cur);
    if (cur.month == 12) {
      cur = DateTime(cur.year + 1, 1);
    } else {
      cur = DateTime(cur.year, cur.month + 1);
    }
  }
  return res;
}

/// Aggregate records into day buckets between [start] and [end] (inclusive).
List<AggregatedPoint> aggregateByDay(Iterable<PomodoroRecord> records, DateTime start, DateTime end) {
  final buckets = {
    for (final day in _daysInRange(start, end)) day: AggregatedPoint(bucketStart: day),
  };
  for (final r in records) {
    final k = startOfDay(r.date);
    if (!k.isBefore(startOfDay(start)) && !k.isAfter(startOfDay(end))) {
      final b = buckets[k];
      if (b != null) {
        b.crushed += r.crushedTomatoes;
        b.half += r.halfTomatoes;
        b.whole += r.wholeTomatoes;
      }
    }
  }
  final list = buckets.values.toList()
    ..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));
  return list;
}

/// Aggregate records into month buckets between [startMonth] and [endMonth] (inclusive).
List<AggregatedPoint> aggregateByMonth(Iterable<PomodoroRecord> records, DateTime startMonth, DateTime endMonth) {
  final buckets = {
    for (final m in _monthsInRange(startMonth, endMonth)) m: AggregatedPoint(bucketStart: m),
  };
  for (final r in records) {
    final k = startOfMonth(r.date);
    if (!k.isBefore(startOfMonth(startMonth)) && !k.isAfter(startOfMonth(endMonth))) {
      final b = buckets[k];
      if (b != null) {
        b.crushed += r.crushedTomatoes;
        b.half += r.halfTomatoes;
        b.whole += r.wholeTomatoes;
      }
    }
  }
  final list = buckets.values.toList()
    ..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));
  return list;
}

/// Build time range buckets for charting.
List<AggregatedPoint> buildRange(TimeRange range, Iterable<PomodoroRecord> records, {DateTime? now}) {
  final n = now ?? DateTime.now();
  switch (range) {
    case TimeRange.day:
      final start = startOfDay(n);
      return aggregateByDay(records.where((r) => startOfDay(r.date).isAtSameMomentAs(start)), start, start);
    case TimeRange.week:
      final end = startOfDay(n);
      final start = end.subtract(const Duration(days: 6)); // last 7 days
      return aggregateByDay(records, start, end);
    case TimeRange.month:
      final end = startOfDay(n);
      final start = end.subtract(const Duration(days: 29)); // last 30 days
      return aggregateByDay(records, start, end);
    case TimeRange.year:
      final endM = startOfMonth(n);
      final startM = DateTime(endM.year, endM.month - 11);
      return aggregateByMonth(records, startM, endM);
    case TimeRange.all:
      if (records.isEmpty) return const [];
      final sorted = records.toList()..sort((a, b) => a.date.compareTo(b.date));
      final first = sorted.first.date;
      final last = sorted.last.date;
      // If span > 1 year, use months; else use days.
      if (last.difference(first).inDays > 365) {
        return aggregateByMonth(records, startOfMonth(first), startOfMonth(last));
      } else {
        return aggregateByDay(records, startOfDay(first), startOfDay(last));
      }
  }
}

class TodayComparison {
  final int tomatoesToday;
  final int tomatoesYesterday;
  final int minutesToday;
  final int minutesYesterday;

  const TodayComparison({
    required this.tomatoesToday,
    required this.tomatoesYesterday,
    required this.minutesToday,
    required this.minutesYesterday,
  });

  int get tomatoDelta => tomatoesToday - tomatoesYesterday;
  int get minuteDelta => minutesToday - minutesYesterday;
}

TodayComparison computeTodayComparison(Iterable<PomodoroRecord> records, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final todayStart = startOfDay(n);
  final yesterdayStart = startOfYesterday(n);
  final yesterdayEnd = todayStart.subtract(const Duration(seconds: 1));

  int tToday = 0, mToday = 0, tY = 0, mY = 0;

  for (final r in records) {
    final d = r.date;
    final s = startOfDay(d);
    if (s.isAtSameMomentAs(todayStart)) {
      tToday += recordTomatoes(r);
      mToday += recordMinutes(r);
    } else if (!s.isBefore(yesterdayStart) && !s.isAfter(yesterdayEnd)) {
      tY += recordTomatoes(r);
      mY += recordMinutes(r);
    }
  }

  return TodayComparison(
    tomatoesToday: tToday,
    tomatoesYesterday: tY,
    minutesToday: mToday,
    minutesYesterday: mY,
  );
}

/// Friendly label for a bucket on X axis.
String labelForBucket(DateTime d, TimeRange range) {
  switch (range) {
    case TimeRange.day:
      // single day: label with weekday and date
      return '${_weekdayShort(d.weekday)} ${d.month}/${d.day}';
    case TimeRange.week:
      return _weekdayShort(d.weekday);
    case TimeRange.month:
      // show day of month
      return d.day.toString();
    case TimeRange.year:
      return _monthShort(d.month);
    case TimeRange.all:
      // Choose based on what it is (month if day==1, otherwise day)
      if (d.day == 1) return _monthShort(d.month);
      return '${d.month}/${d.day}';
  }
}

String _weekdayShort(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  // Dart weekday is 1..7 Mon..Sun
  return names[(weekday - 1) % 7];
}

String _monthShort(int month) {
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return names[(month - 1) % 12];
}
