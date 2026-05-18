import 'date_utils.dart';

enum TabletStatus { active, expiring, expired }

TabletStatus statusFor(DateTime endDate, {DateTime? now}) {
  final DateTime today = now == null ? todayUtc() : toUtcMidnight(now);
  final DateTime end = toUtcMidnight(endDate);
  final DateTime cutoff = today.add(const Duration(days: 7));
  if (end.isBefore(today)) return TabletStatus.expired;
  if (!end.isAfter(cutoff)) return TabletStatus.expiring;
  return TabletStatus.active;
}

extension TabletStatusX on TabletStatus {
  String get label {
    switch (this) {
      case TabletStatus.active:
        return 'Active';
      case TabletStatus.expiring:
        return 'Expiring soon';
      case TabletStatus.expired:
        return 'Expired';
    }
  }
}
