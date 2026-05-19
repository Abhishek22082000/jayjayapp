import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../models/tablet.dart';
import '../providers/tablets_providers.dart';
import '../utils/date_utils.dart';
import '../widgets/app_bar_brand.dart';
import '../widgets/brand_gradient_button.dart';
import '../widgets/expiring_banner.dart';
import '../widgets/stat_card.dart';
import 'barcode_scanner_screen.dart';

// Home / analytics screen. The tablet list lives at /tablets — this screen
// shows only top-line numbers, the expiring banner, and quick actions.
//
// Stat cards are tappable: each card navigates to /tablets with a status
// filter pre-applied. The scan FAB opens the camera; a hit jumps to the
// detail page, a miss shows a snackbar.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Tablet>> async = ref.watch(tabletsStreamProvider);
    final DashboardStats stats = ref.watch(statsProvider);
    final List<Tablet> expiring = ref.watch(expiringSoonProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBarBrand(
        actions: <Widget>[
          OutlinedButton.icon(
            icon: const Icon(Icons.list_alt_outlined, size: 18),
            label: const Text('All tablets'),
            onPressed: () => context.push('/tablets'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.view_list_outlined, size: 18),
            label: const Text('By Tablet'),
            onPressed: () => context.push('/grouped'),
          ),
          const SizedBox(width: 8),
          BrandGradientButton(
            label: 'Add',
            icon: Icons.add,
            onPressed: () => context.push('/tablets/new'),
          ),
        ],
        compactActions: <Widget>[
          IconButton(
            tooltip: 'All tablets',
            icon: const Icon(Icons.list_alt_outlined),
            color: AppColors.primaryDark,
            onPressed: () => context.push('/tablets'),
          ),
          IconButton(
            tooltip: 'By Tablet',
            icon: const Icon(Icons.view_list_outlined),
            color: AppColors.primaryDark,
            onPressed: () => context.push('/grouped'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.control),
              boxShadow: AppShadows.soft,
            ),
            child: IconButton(
              tooltip: 'Add',
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => context.push('/tablets/new'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _scanAndJump(context, ref),
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load: $e',
                  style: const TextStyle(color: AppColors.dangerText)),
            ),
          ),
          data: (_) => LayoutBuilder(builder:
              (BuildContext ctx, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _header(),
                  const SizedBox(height: 14),
                  _stats(context, stats, wide),
                  const SizedBox(height: 14),
                  ExpiringBanner(
                    items: expiring,
                    onSeeByTablet: () => context.push('/grouped'),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _header() {
    final String today = formatDmy(DateTime.now().toUtc());
    return Row(
      children: <Widget>[
        Text('Dashboard', style: AppTextStyles.heading),
        const Spacer(),
        Text(today, style: AppTextStyles.bodyMuted),
      ],
    );
  }

  Widget _stats(BuildContext context, DashboardStats s, bool wide) {
    Widget tap(Widget card, String statusQuery) {
      return InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/tablets?status=$statusQuery'),
        child: card,
      );
    }

    final List<Widget> cards = <Widget>[
      tap(
        StatCard(
          label: 'Total batches',
          value: '${s.total}',
          subtitle: '${s.totalUnits} units total',
          icon: Icons.inventory_2_outlined,
          tone: StatTone.total,
        ),
        'all',
      ),
      tap(
        StatCard(
          label: 'Active',
          value: '${s.active}',
          icon: Icons.check_circle_outline,
          tone: StatTone.active,
        ),
        'active',
      ),
      tap(
        StatCard(
          label: 'Expiring ≤7 days',
          value: '${s.expiring}',
          icon: Icons.schedule,
          tone: StatTone.expiring,
        ),
        'expiring',
      ),
      tap(
        StatCard(
          label: 'Expired',
          value: '${s.expired}',
          icon: Icons.error_outline,
          tone: StatTone.expired,
        ),
        'expired',
      ),
    ];
    if (wide) {
      return Row(
        children: <Widget>[
          for (int i = 0; i < cards.length; i++) ...<Widget>[
            Expanded(child: cards[i]),
            if (i != cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }
    return Column(
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _scanAndJump(BuildContext context, WidgetRef ref) async {
    final String? code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext _) => const BarcodeScannerScreen(),
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    final Tablet? hit = ref.read(tabletByBarcodeProvider(code));
    if (!context.mounted) return;
    if (hit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No tablet found for barcode "$code"')),
      );
      return;
    }
    context.push('/tablets/${hit.id}');
  }
}
