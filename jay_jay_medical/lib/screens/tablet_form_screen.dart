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

class TabletFormScreen extends ConsumerStatefulWidget {
  const TabletFormScreen({super.key, this.editId});
  final String? editId;
  bool get isEdit => editId != null;

  @override
  ConsumerState<TabletFormScreen> createState() => _TabletFormScreenState();
}

class _TabletFormScreenState extends ConsumerState<TabletFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tabletCtrl = TextEditingController();
  final TextEditingController _manufacturerCtrl = TextEditingController();
  final TextEditingController _batchCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _clientCtrl = TextEditingController();
  final FocusNode _tabletFocus = FocusNode();
  final FocusNode _manufacturerFocus = FocusNode();

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _mfgDate;
  String? _crossFieldError;
  bool _saving = false;
  bool _loadedExisting = false;

  @override
  void dispose() {
    _tabletCtrl.dispose();
    _manufacturerCtrl.dispose();
    _batchCtrl.dispose();
    _quantityCtrl.dispose();
    _clientCtrl.dispose();
    _tabletFocus.dispose();
    _manufacturerFocus.dispose();
    super.dispose();
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
    _startDate = t.startDate;
    _endDate = t.endDate;
    _mfgDate = t.manufacturingDate;
    _loadedExisting = true;
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
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back'),
          ),
        ],
        compactActions: <Widget>[
          IconButton(
            tooltip: 'Back to dashboard',
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primaryDark,
            onPressed: () => context.go('/'),
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
                      TextFormField(
                        controller: _quantityCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: intMin1,
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
                        onPressed: _saving ? null : () => context.go('/'),
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

    setState(() => _saving = true);
    try {
      final repo = ref.read(tabletsRepositoryProvider);
      final Tablet t = Tablet(
        id: widget.editId ?? '',
        tabletName: _tabletCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim(),
        batchNumber: _batchCtrl.text.trim(),
        quantity: int.parse(_quantityCtrl.text.trim()),
        clientName: _clientCtrl.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        manufacturingDate: _mfgDate,
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
