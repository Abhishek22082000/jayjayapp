import 'package:flutter_test/flutter_test.dart';
import 'package:jay_jay_medical/utils/validators.dart';

void main() {
  group('requiredText', () {
    test('null → error', () => expect(requiredText(null), isNotNull));
    test('empty → error', () => expect(requiredText(''), isNotNull));
    test('whitespace → error', () => expect(requiredText('   '), isNotNull));
    test('non-empty → null', () => expect(requiredText('abc'), isNull));
  });

  group('intMin1', () {
    test('empty → error', () => expect(intMin1(''), isNotNull));
    test('not a number → error', () => expect(intMin1('abc'), isNotNull));
    test('zero → error', () => expect(intMin1('0'), isNotNull));
    test('negative → error', () => expect(intMin1('-2'), isNotNull));
    test('1 → null', () => expect(intMin1('1'), isNull));
    test('1000 → null', () => expect(intMin1('1000'), isNull));
  });

  group('endAfterStart', () {
    final DateTime a = DateTime.utc(2026, 5, 18);
    final DateTime b = DateTime.utc(2026, 5, 20);
    test('end before start → error',
        () => expect(endAfterStart(b, a), isNotNull));
    test('end equal start → null',
        () => expect(endAfterStart(a, a), isNull));
    test('end after start → null',
        () => expect(endAfterStart(a, b), isNull));
    test('either null → null', () {
      expect(endAfterStart(null, b), isNull);
      expect(endAfterStart(a, null), isNull);
    });
  });

  group('mfgOnOrBeforeEnd', () {
    final DateTime end = DateTime.utc(2026, 5, 18);
    test('mfg after end → error', () {
      expect(mfgOnOrBeforeEnd(end.add(const Duration(days: 1)), end),
          isNotNull);
    });
    test('mfg equal end → null',
        () => expect(mfgOnOrBeforeEnd(end, end), isNull));
    test('mfg before end → null', () {
      expect(mfgOnOrBeforeEnd(end.subtract(const Duration(days: 1)), end),
          isNull);
    });
  });
}
