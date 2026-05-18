import 'package:intl/intl.dart';

DateTime toUtcMidnight(DateTime d) {
  return DateTime.utc(d.year, d.month, d.day);
}

DateTime todayUtc() {
  final DateTime n = DateTime.now().toUtc();
  return DateTime.utc(n.year, n.month, n.day);
}

final DateFormat _dmy = DateFormat('dd MMM yyyy');
String formatDmy(DateTime d) => _dmy.format(d.toUtc());

int daysBetween(DateTime from, DateTime to) {
  final DateTime a = toUtcMidnight(from);
  final DateTime b = toUtcMidnight(to);
  return b.difference(a).inDays;
}

String dueInDaysLabel(DateTime endDate, {DateTime? now}) {
  final int diff = daysBetween(now ?? todayUtc(), endDate);
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  if (diff > 1) return 'in ${diff}d';
  if (diff == -1) return '1d ago';
  return '${-diff}d ago';
}
