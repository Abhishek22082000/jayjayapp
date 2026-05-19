import '../utils/date_utils.dart';
import '../utils/status_utils.dart';

class Tablet {
  final String id;
  final String clientName;
  final String tabletName;
  final String manufacturer;
  final String batchNumber;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? manufacturingDate;
  final DateTime? createdAt;
  final String? barcodeValue;
  // What unit `quantity` is denominated in. One of 'tablet' | 'strip' |
  // 'packet'. Legacy records that pre-date this field default to 'tablet'.
  final String quantityUnit;

  const Tablet({
    required this.id,
    required this.clientName,
    required this.tabletName,
    required this.manufacturer,
    required this.batchNumber,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    this.manufacturingDate,
    this.createdAt,
    this.barcodeValue,
    this.quantityUnit = 'tablet',
  });

  TabletStatus get status => statusFor(endDate);

  factory Tablet.fromJson(Map<String, dynamic> j) {
    return Tablet(
      id: (j['id'] as String?) ?? '',
      clientName: (j['clientName'] as String?) ?? '',
      tabletName: (j['tabletName'] as String?) ?? '',
      manufacturer: (j['manufacturer'] as String?) ?? '',
      batchNumber: (j['batchNumber'] as String?) ?? '',
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      startDate: _parseDate(j['startDate']) ?? DateTime.utc(1970),
      endDate: _parseDate(j['endDate']) ?? DateTime.utc(1970),
      manufacturingDate: _parseDate(j['manufacturingDate']),
      createdAt: _parseDate(j['createdAt']),
      barcodeValue: (j['barcodeValue'] as String?)?.trim().isEmpty == true
          ? null
          : (j['barcodeValue'] as String?),
      quantityUnit: _normalizeUnit(j['quantityUnit']),
    );
  }

  static String _normalizeUnit(Object? v) {
    if (v is String && (v == 'tablet' || v == 'strip' || v == 'packet')) return v;
    return 'tablet';
  }

  // Payload sent to the API on create/update.
  // Dates are serialized as YYYY-MM-DD to match the Next.js web form's
  // <input type="date"> output, so both clients write identical shapes.
  Map<String, dynamic> toJsonPayload() {
    String ymd(DateTime d) {
      final DateTime m = toUtcMidnight(d);
      final String mm = m.month.toString().padLeft(2, '0');
      final String dd = m.day.toString().padLeft(2, '0');
      return '${m.year}-$mm-$dd';
    }
    return <String, dynamic>{
      'clientName': clientName,
      'tabletName': tabletName,
      'manufacturer': manufacturer,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'startDate': ymd(startDate),
      'endDate': ymd(endDate),
      'manufacturingDate': manufacturingDate == null ? null : ymd(manufacturingDate!),
      'barcodeValue': barcodeValue,
      'quantityUnit': quantityUnit,
    };
  }

  Tablet copyWith({
    String? id,
    String? clientName,
    String? tabletName,
    String? manufacturer,
    String? batchNumber,
    int? quantity,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? manufacturingDate,
    bool clearMfg = false,
    DateTime? createdAt,
    String? barcodeValue,
    bool clearBarcode = false,
    String? quantityUnit,
  }) {
    return Tablet(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      tabletName: tabletName ?? this.tabletName,
      manufacturer: manufacturer ?? this.manufacturer,
      batchNumber: batchNumber ?? this.batchNumber,
      quantity: quantity ?? this.quantity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      manufacturingDate:
          clearMfg ? null : (manufacturingDate ?? this.manufacturingDate),
      createdAt: createdAt ?? this.createdAt,
      barcodeValue: clearBarcode ? null : (barcodeValue ?? this.barcodeValue),
      quantityUnit: quantityUnit ?? this.quantityUnit,
    );
  }
}

// Accepts:
//   "YYYY-MM-DD"                       (Next.js web form output)
//   "YYYY-MM-DDTHH:MM:SS[.sss][Z]"     (full ISO timestamps)
//   null / empty                       → returns null
// Date-only strings are pinned to UTC midnight so calendar math is stable
// regardless of the device's local timezone.
final RegExp _dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');

DateTime? _parseDate(Object? v) {
  if (v is! String || v.isEmpty) return null;
  if (_dateOnly.hasMatch(v)) {
    final List<String> parts = v.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
  return DateTime.parse(v).toUtc();
}
