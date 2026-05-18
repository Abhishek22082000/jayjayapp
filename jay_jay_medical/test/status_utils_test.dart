import 'package:flutter_test/flutter_test.dart';
import 'package:jay_jay_medical/utils/date_utils.dart';
import 'package:jay_jay_medical/utils/status_utils.dart';

void main() {
  group('statusFor', () {
    final DateTime now = DateTime.utc(2026, 5, 18);

    test('endDate yesterday → expired', () {
      expect(statusFor(now.subtract(const Duration(days: 1)), now: now),
          TabletStatus.expired);
    });

    test('endDate today → expiring (inclusive lower bound)', () {
      expect(statusFor(now, now: now), TabletStatus.expiring);
    });

    test('endDate today + 7 days → expiring (inclusive upper bound)', () {
      expect(statusFor(now.add(const Duration(days: 7)), now: now),
          TabletStatus.expiring);
    });

    test('endDate today + 8 days → active', () {
      expect(statusFor(now.add(const Duration(days: 8)), now: now),
          TabletStatus.active);
    });

    test('endDate today + 365 days → active', () {
      expect(statusFor(now.add(const Duration(days: 365)), now: now),
          TabletStatus.active);
    });

    test('time-of-day component is ignored (midnight comparison)', () {
      final DateTime endLate = DateTime.utc(2026, 5, 18, 23, 59, 59);
      // endLate falls on the same day as `now`, so status should be expiring.
      expect(statusFor(endLate, now: now), TabletStatus.expiring);
    });

    test('toUtcMidnight strips the time component', () {
      final DateTime d = DateTime(2026, 5, 18, 13, 22);
      final DateTime mid = toUtcMidnight(d);
      expect(mid, DateTime.utc(2026, 5, 18));
    });
  });
}
