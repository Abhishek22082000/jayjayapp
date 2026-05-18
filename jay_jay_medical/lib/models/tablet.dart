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
  });

  TabletStatus get status => statusFor(endDate);

  factory Tablet.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(Object? v) {
      if (v is String && v.isNotEmpty) return DateTime.parse(v).toUtc();
      return DateTime.utc(1970);
    }
    DateTime? parseDateOrNull(Object? v) {
      if (v is String && v.isNotEmpty) return DateTime.parse(v).toUtc();
      return null;
    }
    return Tablet(
      id: (j['id'] as String?) ?? '',
      clientName: (j['clientName'] as String?) ?? '',
      tabletName: (j['tabletName'] as String?) ?? '',
      manufacturer: (j['manufacturer'] as String?) ?? '',
      batchNumber: (j['batchNumber'] as String?) ?? '',
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      startDate: parseDate(j['startDate']),
      endDate: parseDate(j['endDate']),
      manufacturingDate: parseDateOrNull(j['manufacturingDate']),
      createdAt: parseDateOrNull(j['createdAt']),
    );
  }

  // Payload sent to the API on create/update.
  Map<String, dynamic> toJsonPayload() {
    return <String, dynamic>{
      'clientName': clientName,
      'tabletName': tabletName,
      'manufacturer': manufacturer,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'startDate': toUtcMidnight(startDate).toIso8601String(),
      'endDate': toUtcMidnight(endDate).toIso8601String(),
      'manufacturingDate': manufacturingDate == null
          ? null
          : toUtcMidnight(manufacturingDate!).toIso8601String(),
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
    );
  }
}
