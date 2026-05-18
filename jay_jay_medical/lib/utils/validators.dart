String? requiredText(String? value, {String field = 'This field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$field is required';
  }
  return null;
}

String? intMin1(String? value, {String field = 'Quantity'}) {
  if (value == null || value.trim().isEmpty) {
    return '$field is required';
  }
  final int? n = int.tryParse(value.trim());
  if (n == null) return '$field must be a whole number';
  if (n < 1) return '$field must be at least 1';
  return null;
}

String? endAfterStart(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  if (end.isBefore(start)) {
    return 'Expiry date must be on or after start date';
  }
  return null;
}

String? mfgOnOrBeforeEnd(DateTime? mfg, DateTime? end) {
  if (mfg == null || end == null) return null;
  if (mfg.isAfter(end)) {
    return 'Manufacturing date must be on or before expiry date';
  }
  return null;
}
