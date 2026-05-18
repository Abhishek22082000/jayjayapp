import 'package:flutter_test/flutter_test.dart';
import 'package:jay_jay_medical/models/tablet.dart';
import 'package:jay_jay_medical/utils/grouping.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 5, 18);

  Tablet make({
    required String id,
    required String tabletName,
    required String manufacturer,
    required String clientName,
    required int quantity,
    required DateTime endDate,
  }) {
    return Tablet(
      id: id,
      clientName: clientName,
      tabletName: tabletName,
      manufacturer: manufacturer,
      batchNumber: 'B$id',
      quantity: quantity,
      startDate: now.subtract(const Duration(days: 30)),
      endDate: endDate,
    );
  }

  test('two clients of same (tablet, mfr) collapse into one group', () {
    final List<Tablet> rows = <Tablet>[
      make(
        id: '1',
        tabletName: 'Paracetamol',
        manufacturer: 'Acme',
        clientName: 'Alice',
        quantity: 10,
        endDate: now.add(const Duration(days: 3)),
      ),
      make(
        id: '2',
        tabletName: 'Paracetamol',
        manufacturer: 'Acme',
        clientName: 'Bob',
        quantity: 25,
        endDate: now.add(const Duration(days: 5)),
      ),
      make(
        id: '3',
        tabletName: 'Paracetamol',
        manufacturer: 'Other',
        clientName: 'Carol',
        quantity: 7,
        endDate: now.subtract(const Duration(days: 2)),
      ),
    ];

    final List<TabletGroup> groups = groupTablets(rows, now: now);

    expect(groups.length, 2);

    // Group 1: Paracetamol / Acme — two batches, qty 35, two expiring clients.
    final TabletGroup acme =
        groups.firstWhere((TabletGroup g) => g.manufacturer == 'Acme');
    expect(acme.batches, 2);
    expect(acme.totalQuantity, 35);
    expect(acme.expiringCount, 2);
    expect(acme.expiringUnits, 35);
    expect(acme.expiredCount, 0);
    expect(acme.clientsWithExpiring, <String>['Alice', 'Bob']);

    // Group 2: Paracetamol / Other — one expired batch.
    final TabletGroup other =
        groups.firstWhere((TabletGroup g) => g.manufacturer == 'Other');
    expect(other.batches, 1);
    expect(other.expiredCount, 1);
    expect(other.expiredUnits, 7);
    expect(other.expiringCount, 0);
    expect(other.clientsWithExpiring, isEmpty);
  });

  test('grouping is sorted by urgency desc then name asc', () {
    final List<Tablet> rows = <Tablet>[
      make(
        id: 'z',
        tabletName: 'Zebra',
        manufacturer: 'Z',
        clientName: 'X',
        quantity: 1,
        endDate: now.add(const Duration(days: 30)), // active
      ),
      make(
        id: 'a',
        tabletName: 'Aspirin',
        manufacturer: 'A',
        clientName: 'X',
        quantity: 1,
        endDate: now.add(const Duration(days: 60)), // active
      ),
      make(
        id: 'p',
        tabletName: 'Paracetamol',
        manufacturer: 'P',
        clientName: 'X',
        quantity: 1,
        endDate: now.add(const Duration(days: 1)), // expiring
      ),
    ];
    final List<TabletGroup> groups = groupTablets(rows, now: now);
    expect(groups.map((TabletGroup g) => g.tabletName).toList(),
        <String>['Paracetamol', 'Aspirin', 'Zebra']);
  });
}
