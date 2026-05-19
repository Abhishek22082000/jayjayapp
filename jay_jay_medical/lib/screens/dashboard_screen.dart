import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../models/tablet.dart';
import '../providers/filters_provider.dart';
import '../providers/tablets_providers.dart';
import '../utils/date_utils.dart';
import '../widgets/app_bar_brand.dart';
import '../widgets/brand_gradient_button.dart';
import '../widgets/expiring_banner.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openList(BuildContext context, WidgetRef ref, StatusFilter status) {
    // Clear any drill-down chips so the status filter is the only constraint.
    ref.read(filtersProvider.notifier).reset();
    final String s = switch (status) {
      StatusFilter.all => 'all',
      StatusFilter.active => 'active',
      StatusFilter.expiring => 'expiring',
      StatusFilter.expired => 'expired',
    };
    context.push('/tablets?status=$s');
  }

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
        onPressed: () => context.push('/scan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan'),
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
                  _stats(context, ref, stats, wide),
                  const SizedBox(height: 14),
                  ExpiringBanner(
                    items: expiring,
                    onSeeByTablet: () => context.push('/grouped'),
                  ),
                  // Bottom padding so the FAB doesn't cover content when the
                  // banner is empty.
                  const SizedBox(height: 80),
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

  Widget _stats(
      BuildContext context, WidgetRef ref, DashboardStats s, bool wide) {
    final List<Widget> cards = <Widget>[
      StatCard(
        label: 'Total batches',
        value: '${s.total}',
        subtitle: '${s.totalUnits} units total',
        icon: Icons.inventory_2_outlined,
        tone: StatTone.total,
        onTap: () => _openList(context, ref, StatusFilter.all),
      ),
      StatCard(
        label: 'Active',
        value: '${s.active}',
        icon: Icons.check_circle_outline,
        tone: StatTone.active,
        onTap: () => _openList(context, ref, StatusFilter.active),
      ),
      StatCard(
        label: 'Expiring ≤7 days',
        value: '${s.expiring}',
        icon: Icons.schedule,
        tone: StatTone.expiring,
        onTap: () => _openList(context, ref, StatusFilter.expiring),
      ),
      StatCard(
        label: 'Expired',
        value: '${s.expired}',
        icon: Icons.error_outline,
        tone: StatTone.expired,
        onTap: () => _openList(context, ref, StatusFilter.expired),
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
}
