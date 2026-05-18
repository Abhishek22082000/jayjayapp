import '../models/tablet.dart';
import 'status_utils.dart';

class TabletGroup {
  final String tabletName;
  final String manufacturer;
  final List<String> clientsWithExpiring;
  final int batches;
  final int totalQuantity;
  final int expiringCount;
  final int expiringUnits;
  final int expiredCount;
  final int expiredUnits;
  final DateTime earliestExpiry;

  const TabletGroup({
    required this.tabletName,
    required this.manufacturer,
    required this.clientsWithExpiring,
    required this.batches,
    required this.totalQuantity,
    required this.expiringCount,
    required this.expiringUnits,
    required this.expiredCount,
    required this.expiredUnits,
    required this.earliestExpiry,
  });

  int get urgencyScore => expiringCount + expiredCount;

  bool get hasExpired => expiredCount > 0;
  bool get hasExpiring => expiringCount > 0;
  bool get needsAttention => hasExpired || hasExpiring;
}

// TODO: when the `tablets` collection grows beyond ~1000 documents,
// move this aggregation into a scheduled Cloud Function and read the
// pre-computed results instead of doing it client-side.
List<TabletGroup> groupTablets(List<Tablet> tablets, {DateTime? now}) {
  final Map<String, List<Tablet>> bucketed = <String, List<Tablet>>{};
  for (final Tablet t in tablets) {
    final String key = '${t.tabletName.toLowerCase()}|${t.manufacturer.toLowerCase()}';
    bucketed.putIfAbsent(key, () => <Tablet>[]).add(t);
  }

  final List<TabletGroup> groups = <TabletGroup>[];
  bucketed.forEach((_, List<Tablet> rows) {
    int totalQty = 0;
    int expiringCount = 0;
    int expiringUnits = 0;
    int expiredCount = 0;
    int expiredUnits = 0;
    DateTime earliest = rows.first.endDate;
    final Set<String> expiringClients = <String>{};
    for (final Tablet t in rows) {
      totalQty += t.quantity;
      if (t.endDate.isBefore(earliest)) earliest = t.endDate;
      final TabletStatus s = statusFor(t.endDate, now: now);
      if (s == TabletStatus.expiring) {
        expiringCount++;
        expiringUnits += t.quantity;
        if (t.clientName.isNotEmpty) expiringClients.add(t.clientName);
      } else if (s == TabletStatus.expired) {
        expiredCount++;
        expiredUnits += t.quantity;
      }
    }
    groups.add(TabletGroup(
      tabletName: rows.first.tabletName,
      manufacturer: rows.first.manufacturer,
      clientsWithExpiring: expiringClients.toList()..sort(),
      batches: rows.length,
      totalQuantity: totalQty,
      expiringCount: expiringCount,
      expiringUnits: expiringUnits,
      expiredCount: expiredCount,
      expiredUnits: expiredUnits,
      earliestExpiry: earliest,
    ));
  });

  groups.sort((TabletGroup a, TabletGroup b) {
    final int byUrgency = b.urgencyScore.compareTo(a.urgencyScore);
    if (byUrgency != 0) return byUrgency;
    return a.tabletName.toLowerCase().compareTo(b.tabletName.toLowerCase());
  });
  return groups;
}
