import 'package:flutter_test/flutter_test.dart';
import 'package:jay_jay_medical/models/tablet.dart';

void main() {
  group('Tablet.fromJson / toJsonPayload', () {
    test('round-trips a barcode value', () {
      final Tablet t = Tablet.fromJson(<String, dynamic>{
        'id': 'abc',
        'clientName': 'Maria',
        'tabletName': 'Paracetamol',
        'manufacturer': 'Acme',
        'batchNumber': 'B042',
        'quantity': 50,
        'startDate': '2026-05-18',
        'endDate': '2026-08-18',
        'manufacturingDate': '2026-01-10',
        'barcodeValue': '012345678905',
      });
      expect(t.barcodeValue, '012345678905');
      expect(t.toJsonPayload()['barcodeValue'], '012345678905');
    });

    test('treats missing or empty barcode as null', () {
      final Tablet missing = Tablet.fromJson(<String, dynamic>{
        'clientName': 'X',
        'tabletName': 'Y',
        'manufacturer': 'Z',
        'batchNumber': 'B1',
        'quantity': 1,
        'startDate': '2026-05-18',
        'endDate': '2026-08-18',
      });
      expect(missing.barcodeValue, isNull);

      final Tablet empty = Tablet.fromJson(<String, dynamic>{
        'clientName': 'X',
        'tabletName': 'Y',
        'manufacturer': 'Z',
        'batchNumber': 'B1',
        'quantity': 1,
        'startDate': '2026-05-18',
        'endDate': '2026-08-18',
        'barcodeValue': '   ',
      });
      expect(empty.barcodeValue, isNull);
    });
  });
}
