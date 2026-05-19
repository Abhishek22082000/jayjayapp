import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../models/tablet.dart';
import '../providers/tablets_providers.dart';
import '../utils/date_utils.dart';
import '../utils/status_utils.dart';
import '../widgets/app_bar_brand.dart';
import '../widgets/brand_gradient_button.dart';
import '../widgets/pill.dart';

// Read-only tablet view. Reached from:
//   • tapping a row in the list
//   • a successful barcode scan from home
//
// Pulls from the polled in-memory list first via tabletByIdProvider; if the
// id isn't in the cache (deep-link or stale poll) it falls back to a direct
// GET /api/tablets/:id via the repository.
class TabletDetailScreen extends ConsumerStatefulWidget {
  const TabletDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<TabletDetailScreen> createState() => _TabletDetailScreenState();
}

class _TabletDetailScreenState extends ConsumerState<TabletDetailScreen> {
  Future<Tablet?>? _remoteFetch;

  @override
  Widget build(BuildContext context) {
    final Tablet? cached = ref.watch(tabletByIdProvider(widget.id));
    if (cached != null) {
      return _body(context, cached);
    }
    // Not in cache yet — kick off a direct fetch once.
    _remoteFetch ??= ref.read(tabletsRepositoryProvider).fetchById(widget.id);
    return FutureBuilder<Tablet?>(
      future: _remoteFetch,
      builder: (BuildContext ctx, AsyncSnapshot<Tablet?> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _shell(context,
              const Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return _shell(
            context,
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load: ${snap.error}',
                    style: const TextStyle(color: AppColors.dangerText)),
              ),
            ),
          );
        }
        final Tablet? t = snap.data;
        if (t == null) {
          return _shell(
            context,
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Tablet not found.'),
              ),
            ),
          );
        }
        return _body(context, t);
      },
    );
  }

  Widget _shell(BuildContext context, Widget body) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBarBrand(
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => _goBack(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back'),
          ),
        ],
        compactActions: <Widget>[
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primaryDark,
            onPressed: () => _goBack(context),
          ),
        ],
      ),
      body: SafeArea(top: false, child: body),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Widget _body(BuildContext context, Tablet t) {
    final TabletStatus status = t.status;
    return _shell(
      context,
      LayoutBuilder(builder: (BuildContext ctx, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _header(t, status),
                const SizedBox(height: 14),
                _section(
                  title: 'TABLET INFORMATION',
                  children: <Widget>[
                    _row(wide, 'Tablet name', t.tabletName),
                    _row(wide, 'Manufacturer', t.manufacturer),
                    _row(wide, 'Batch number', '#${t.batchNumber}'),
                    _row(wide, 'Quantity', '${t.quantity}'),
                    _row(wide, 'Barcode',
                        (t.barcodeValue == null || t.barcodeValue!.isEmpty)
                            ? '—'
                            : t.barcodeValue!),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'CLIENT & DATES',
                  children: <Widget>[
                    _row(wide, 'Client', t.clientName),
                    _row(
                        wide,
                        'Manufacturing date',
                        t.manufacturingDate == null
                            ? '—'
                            : formatDmy(t.manufacturingDate!)),
                    _row(wide, 'Start date', formatDmy(t.startDate)),
                    _row(
                        wide,
                        'Expiry date',
                        '${formatDmy(t.endDate)} · ${dueInDaysLabel(t.endDate)}'),
                    if (t.createdAt != null)
                      _row(wide, 'Created', formatDmy(t.createdAt!)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                      onPressed: () => _goBack(context),
                    ),
                    const SizedBox(width: 10),
                    BrandGradientButton(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      onPressed: () =>
                          context.push('/tablets/${t.id}/edit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _header(Tablet t, TabletStatus status) {
    final PillTone tone = switch (status) {
      TabletStatus.active => PillTone.success,
      TabletStatus.expiring => PillTone.warning,
      TabletStatus.expired => PillTone.danger,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.tabletName, style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                '${t.manufacturer} · batch #${t.batchNumber}',
                style: AppTextStyles.bodyMuted,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Pill(label: status.label, tone: tone),
      ],
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
            if (i != children.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _row(bool wide, String label, String value) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 180,
            child: Text(label, style: AppTextStyles.sectionLabel),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.sectionLabel),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }
}
