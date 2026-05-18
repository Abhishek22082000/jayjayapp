import 'package:flutter_test/flutter_test.dart';
import 'package:jay_jay_medical/utils/date_utils.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 5, 18);

  group('dueInDaysLabel', () {
    test('today', () {
      expect(dueInDaysLabel(now, now: now), 'today');
    });
    test('tomorrow', () {
      expect(dueInDaysLabel(now.add(const Duration(days: 1)), now: now),
          'tomorrow');
    });
    test('in 3d', () {
      expect(dueInDaysLabel(now.add(const Duration(days: 3)), now: now),
          'in 3d');
    });
    test('1d ago', () {
      expect(dueInDaysLabel(now.subtract(const Duration(days: 1)), now: now),
          '1d ago');
    });
    test('2d ago', () {
      expect(dueInDaysLabel(now.subtract(const Duration(days: 2)), now: now),
          '2d ago');
    });
  });

  group('formatDmy', () {
    test('formats as dd MMM yyyy', () {
      expect(formatDmy(DateTime.utc(2026, 5, 21)), '21 May 2026');
    });
  });

  group('daysBetween', () {
    test('ignores time component', () {
      final DateTime a = DateTime.utc(2026, 5, 18, 23, 59);
      final DateTime b = DateTime.utc(2026, 5, 19, 0, 1);
      expect(daysBetween(a, b), 1);
    });
  });
}
