import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../models/tablet.dart';
import '../providers/tablets_providers.dart';
import '../utils/date_utils.dart';
import '../utils/validators.dart';
import '../widgets/app_bar_brand.dart';
import '../widgets/brand_gradient_button.dart';
import 'barcode_scanner_screen.dart';

class TabletFormScreen extends ConsumerStatefulWidget {
  const TabletFormScreen({super.key, this.editId, this.prefillBarcode});
  final String? editId;
  // Pre-populates the barcode field on /tablets/new when the home scanner
  // hands off an unknown code via "no match → create new". Ignored on edit.
  final String? prefillBarcode;
  bool get isEdit => editId != null;

  @override
  ConsumerState<TabletFormScreen> createState() => _TabletFormScreenState();
}

enum QuantityUnit { tablet, strip, packet }

class _TabletFormScreenState extends ConsumerState<TabletFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tabletCtrl = TextEditingController();
  final TextEditingController _manufacturerCtrl = TextEditingController();
  final TextEditingController _batchCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _clientCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();
  final TextEditingController _tabletsPerStripCtrl = TextEditingController();
  final TextEditingController _stripsPerPacketCtrl = TextEditingController();
  final FocusNode _tabletFocus = FocusNode();
  final FocusNode _manufacturerFocus = FocusNode();

  // What unit the user is entering Quantity in. On save we always convert
  // back to individual tablets (the base unit `Tablet.quantity`).
  QuantityUnit _quantityUnit = QuantityUnit.tablet;

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _mfgDate;
  String? _crossFieldError;
  bool _saving = false;
  bool _loadedExisting = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isEdit &&
        widget.prefillBarcode != null &&
        widget.prefillBarcode!.isNotEmpty) {
      _barcodeCtrl.text = widget.prefillBarcode!;
    }
  }

  @override
  void dispose() {
    _tabletCtrl.dispose();
    _manufacturerCtrl.dispose();
    _batchCtrl.dispose();
    _quantityCtrl.dispose();
    _clientCtrl.dispose();
    _barcodeCtrl.dispose();
    _tabletsPerStripCtrl.dispose();
    _stripsPerPacketCtrl.dispose();
    _tabletFocus.dispose();
    _manufacturerFocus.dispose();
    super.dispose();
  }

  // Pop back to whatever opened the form (dashboard or grouped).
  // Falls back to the dashboard if the form was reached via a direct
  // deep link with no history to pop.
  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _hydrateFromExisting() {
    if (_loadedExisting || !widget.isEdit) return;
    final List<Tablet> all =
        ref.read(tabletsStreamProvider).maybeWhen<List<Tablet>>(
              data: (List<Tablet> v) => v,
              orElse: () => const <Tablet>[],
            );
    Tablet? t;
    for (final Tablet x in all) {
      if (x.id == widget.editId) {
        t = x;
        break;
      }
    }
    if (t == null) return;
    _tabletCtrl.text = t.tabletName;
    _manufacturerCtrl.text = t.manufacturer;
    _batchCtrl.text = t.batchNumber;
    _quantityCtrl.text = '${t.quantity}';
    _clientCtrl.text = t.clientName;
    _barcodeCtrl.text = t.barcodeValue ?? '';
    _tabletsPerStripCtrl.text =
        t.tabletsPerStrip == null ? '' : '${t.tabletsPerStrip}';
    _stripsPerPacketCtrl.text =
        t.stripsPerPacket == null ? '' : '${t.stripsPerPacket}';
    _startDate = t.startDate;
    _endDate = t.endDate;
    _mfgDate = t.manufacturingDate;
    _loadedExisting = true;
  }

  String? _optionalPositiveInt(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final int? n = int.tryParse(v.trim());
    if (n == null || n < 1) return 'Must be 1 or more';
    return null;
  }

  int? _parsedTabletsPerStrip() => int.tryParse(_tabletsPerStripCtrl.text.trim());
  int? _parsedStripsPerPacket() => int.tryParse(_stripsPerPacketCtrl.text.trim());

  // Total tablets the user is about to save, based on the entered quantity
  // and the selected unit. Returns null if inputs are incomplete or the
  // selected unit needs a pack size that isn't filled in yet.
  int? _computedTotalTablets() {
    final int? entered = int.tryParse(_quantityCtrl.text.trim());
    if (entered == null || entered < 1) return null;
    switch (_quantityUnit) {
      case QuantityUnit.tablet:
        return entered;
      case QuantityUnit.strip:
        final int? tps = _parsedTabletsPerStrip();
        if (tps == null || tps < 1) return null;
        return entered * tps;
      case QuantityUnit.packet:
        final int? tps = _parsedTabletsPerStrip();
        final int? spp = _parsedStripsPerPacket();
        if (tps == null || tps < 1 || spp == null || spp < 1) return null;
        return entered * tps * spp;
    }
  }

  String? _quantityPreview() {
    if (_quantityUnit == QuantityUnit.tablet) return null;
    final int? total = _computedTotalTablets();
    if (total == null) return null;
    return '$total tablets';
  }

  String _quantityLabel() {
    switch (_quantityUnit) {
      case QuantityUnit.tablet:
        return 'Number of tablets';
      case QuantityUnit.strip:
        return 'Number of strips';
      case QuantityUnit.packet:
        return 'Number of packets';
    }
  }

  Future<void> _scanBarcodeIntoField() async {
    final String? code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext _) => const BarcodeScannerScreen(),
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    setState(() => _barcodeCtrl.text = code.trim());
  }

  @override
  Widget build(BuildContext context) {
    _hydrateFromExisting();
    final AutocompleteSets ac = ref.watch(autocompleteValuesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBarBrand(
        actions: <Widget>[
          TextButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back'),
          ),
        ],
        compactActions: <Widget>[
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primaryDark,
            onPressed: _goBack,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(widget.isEdit ? 'Edit tablet record' : 'Add a tablet record',
                      style: AppTextStyles.heading),
                  const SizedBox(height: 16),
                  _section(
                    title: 'TABLET INFORMATION',
                    children: <Widget>[
                      _autocompleteField(
                        label: 'Tablet name',
                        controller: _tabletCtrl,
                        focusNode: _tabletFocus,
                        options: ac.tabletNames,
                        validator: (String? v) =>
                            requiredText(v, field: 'Tablet name'),
                      ),
                      _autocompleteField(
                        label: 'Manufacturer',
                        controller: _manufacturerCtrl,
                        focusNode: _manufacturerFocus,
                        options: ac.manufacturers,
                        validator: (String? v) =>
                            requiredText(v, field: 'Manufacturer'),
                      ),
                      TextFormField(
                        controller: _batchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Batch number',
                          prefixText: '#',
                        ),
                        validator: (String? v) =>
                            requiredText(v, field: 'Batch number'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _tabletsPerStripCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Tablets per strip',
                                hintText: 'e.g. 10',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: _optionalPositiveInt,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stripsPerPacketCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Strips per packet',
                                hintText: 'e.g. 10 (optional)',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: _optionalPositiveInt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('UNIT', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<QuantityUnit>(
                          showSelectedIcon: false,
                          segments: const <ButtonSegment<QuantityUnit>>[
                            ButtonSegment<QuantityUnit>(
                                value: QuantityUnit.tablet,
                                label: Text('Tablet')),
                            ButtonSegment<QuantityUnit>(
                                value: QuantityUnit.strip,
                                label: Text('Strip')),
                            ButtonSegment<QuantityUnit>(
                                value: QuantityUnit.packet,
                                label: Text('Packet')),
                          ],
                          selected: <QuantityUnit>{_quantityUnit},
                          onSelectionChanged: (Set<QuantityUnit> s) {
                            setState(() => _quantityUnit = s.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quantityCtrl,
                        decoration: InputDecoration(labelText: _quantityLabel()),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: intMin1,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_quantityPreview() != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          '= ${_quantityPreview()}',
                          style: AppTextStyles.small,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Barcode (optional)',
                                hintText: 'Scan or type',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: IconButton.filledTonal(
                              tooltip: 'Scan barcode',
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _saving ? null : _scanBarcodeIntoField,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    title: 'CLIENT & DATES',
                    children: <Widget>[
                      TextFormField(
                        controller: _clientCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Client name'),
                        validator: (String? v) =>
                            requiredText(v, field: 'Client name'),
                      ),
                      const SizedBox(height: 12),
                      _dateRow(<Widget>[
                        Expanded(
                            child: _dateField(
                                label: 'Manufacturing date (optional)',
                                value: _mfgDate,
                                onPicked: (DateTime? d) =>
                                    setState(() => _mfgDate = d),
                                allowClear: true)),
                      ]),
                      const SizedBox(height: 12),
                      _dateRow(<Widget>[
                        Expanded(
                            child: _dateField(
                                label: 'Start date',
                                value: _startDate,
                                onPicked: (DateTime? d) =>
                                    setState(() => _startDate = d))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _dateField(
                                label: 'Expiry date',
                                value: _endDate,
                                onPicked: (DateTime? d) =>
                                    setState(() => _endDate = d))),
                      ]),
                    ],
                  ),
                  if (_crossFieldError != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius:
                            BorderRadius.circular(AppRadius.control),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(_crossFieldError!,
                          style: const TextStyle(color: AppColors.dangerText)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      const Spacer(),
                      OutlinedButton(
                        onPressed: _saving ? null : _goBack,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      BrandGradientButton(
                        label: widget.isEdit ? 'Update Tablet' : 'Save Tablet',
                        icon: Icons.save_outlined,
                        busy: _saving,
                        onPressed: _saving ? null : _onSave,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 12),
          for (int i = 0; i < children.length; i++) ...<Widget>[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _autocompleteField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Set<String> options,
    required FormFieldValidator<String> validator,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue v) {
        if (v.text.isEmpty) return const Iterable<String>.empty();
        final String q = v.text.toLowerCase();
        return options.where((String o) => o.toLowerCase().contains(q));
      },
      onSelected: (String s) => controller.text = s,
      fieldViewBuilder: (BuildContext ctx, TextEditingController c,
          FocusNode fn, VoidCallback onSubmit) {
        return TextFormField(
          controller: c,
          focusNode: fn,
          decoration: InputDecoration(labelText: label),
          validator: validator,
        );
      },
      optionsViewBuilder: (BuildContext ctx,
          AutocompleteOnSelected<String> onSelected, Iterable<String> opts) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 200, maxWidth: 320),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: <Widget>[
                  for (final String o in opts)
                    InkWell(
                      onTap: () => onSelected(o),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Text(o, style: AppTextStyles.body),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dateRow(List<Widget> children) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPicked,
    bool allowClear = false,
  }) {
    final TextEditingController c = TextEditingController(
      text: value == null ? '' : formatDmy(value),
    );
    return TextFormField(
      controller: c,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: allowClear && value != null
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onPicked(null),
              )
            : const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      onTap: () async {
        final DateTime initial = value ?? DateTime.now().toUtc();
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime.utc(2000),
          lastDate: DateTime.utc(2100),
        );
        if (picked != null) onPicked(toUtcMidnight(picked));
      },
    );
  }

  Future<void> _onSave() async {
    setState(() => _crossFieldError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startDate == null) {
      setState(() => _crossFieldError = 'Start date is required');
      return;
    }
    if (_endDate == null) {
      setState(() => _crossFieldError = 'Expiry date is required');
      return;
    }
    final String? err1 = endAfterStart(_startDate, _endDate);
    if (err1 != null) {
      setState(() => _crossFieldError = err1);
      return;
    }
    final String? err2 = mfgOnOrBeforeEnd(_mfgDate, _endDate);
    if (err2 != null) {
      setState(() => _crossFieldError = err2);
      return;
    }

    // Convert the entered quantity into individual tablets (base unit)
    // based on the selected unit. Strip/Packet need their pack-size fields
    // filled in, else surface a cross-field error and bail.
    final int? totalTablets = _computedTotalTablets();
    if (totalTablets == null) {
      setState(() {
        switch (_quantityUnit) {
          case QuantityUnit.strip:
            _crossFieldError =
                'Set "Tablets per strip" to use the Strip unit.';
            break;
          case QuantityUnit.packet:
            _crossFieldError =
                'Set both "Tablets per strip" and "Strips per packet" to use the Packet unit.';
            break;
          case QuantityUnit.tablet:
            _crossFieldError = 'Enter a quantity of 1 or more.';
            break;
        }
      });
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(tabletsRepositoryProvider);
      final String barcode = _barcodeCtrl.text.trim();
      final Tablet t = Tablet(
        id: widget.editId ?? '',
        tabletName: _tabletCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim(),
        batchNumber: _batchCtrl.text.trim(),
        quantity: totalTablets,
        tabletsPerStrip: _parsedTabletsPerStrip(),
        stripsPerPacket: _parsedStripsPerPacket(),
        clientName: _clientCtrl.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        manufacturingDate: _mfgDate,
        barcodeValue: barcode.isEmpty ? null : barcode,
      );
      if (widget.isEdit) {
        await repo.update(t);
      } else {
        await repo.add(t);
      }
      ref.invalidate(tabletsStreamProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successSoft,
          content: Text(
            widget.isEdit ? 'Tablet updated' : 'Tablet saved',
            style: const TextStyle(color: AppColors.successText),
          ),
        ),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }
}
