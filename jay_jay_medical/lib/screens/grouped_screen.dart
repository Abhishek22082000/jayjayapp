import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../providers/filters_provider.dart';
import '../providers/tablets_providers.dart';
import '../utils/date_utils.dart';
import '../utils/grouping.dart';
import '../widgets/app_bar_brand.dart';
import '../widgets/brand_gradient_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_card.dart';
import '../widgets/pager.dart';
import '../widgets/pill.dart';

class GroupedScreen extends ConsumerStatefulWidget {
  const GroupedScreen({super.key});
  @override
  ConsumerState<GroupedScreen> createState() => _GroupedScreenState();
}

class _GroupedScreenState extends ConsumerState<GroupedScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(groupedFiltersProvider).search;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PagedGroups paged = ref.watch(groupedTabletsProvider);
    final GroupedFilters gf = ref.watch(groupedFiltersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBarBrand(
        actions: <Widget>[
          OutlinedButton.icon(
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: const Text('Dashboard'),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 8),
          BrandGradientButton(
            label: 'Add',
            icon: Icons.add,
            onPressed: () => context.go('/tablets/new'),
          ),
        ],
        compactActions: <Widget>[
          IconButton(
            tooltip: 'Dashboard',
            icon: const Icon(Icons.dashboard_outlined),
            color: AppColors.primaryDark,
            onPressed: () => context.go('/'),
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
              onPressed: () => context.go('/tablets/new'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder:
            (BuildContext ctx, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('By Tablet', style: AppTextStyles.heading),
                const SizedBox(height: 14),
                _filters(gf),
                const SizedBox(height: 14),
                if (paged.totalCount == 0)
                  const EmptyState(
                    icon: Icons.medication_outlined,
                    message:
                        'No tablet groups match these filters.\nTry switching the filter or adding new stock.',
                  )
                else
                  _listCard(paged, wide),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _filters(GroupedFilters gf) {
    return FilterCard(
      children: <Widget>[
        Text('FILTERS', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search tablet or manufacturer',
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
                onChanged: (String v) =>
                    ref.read(groupedFiltersProvider.notifier).setSearch(v),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<GroupedFilter>(
                key: ValueKey<GroupedFilter>(gf.filter),
                initialValue: gf.filter,
                decoration: const InputDecoration(labelText: 'View'),
                items: const <DropdownMenuItem<GroupedFilter>>[
                  DropdownMenuItem<GroupedFilter>(
                      value: GroupedFilter.expiringSoon,
                      child: Text('Expiring ≤7 days')),
                  DropdownMenuItem<GroupedFilter>(
                      value: GroupedFilter.hasExpired,
                      child: Text('Has expired stock')),
                  DropdownMenuItem<GroupedFilter>(
                      value: GroupedFilter.needsAttention,
                      child: Text('Needs attention')),
                  DropdownMenuItem<GroupedFilter>(
                      value: GroupedFilter.all, child: Text('All tablets')),
                ],
                onChanged: (GroupedFilter? v) {
                  if (v != null) {
                    ref
                        .read(groupedFiltersProvider.notifier)
                        .setFilter(v);
                  }
                },
              ),
            ),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                ref.read(groupedFiltersProvider.notifier).reset();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _listCard(PagedGroups paged, bool wide) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('TABLETS', style: AppTextStyles.sectionLabel),
              const Spacer(),
              Text(
                'Showing ${paged.firstRowIndex}–${paged.lastRowIndex} of ${paged.totalCount}',
                style: AppTextStyles.small,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (wide) _headerRow(),
          if (wide) const SizedBox(height: 4),
          for (final TabletGroup g in paged.pageItems)
            _GroupRow(group: g, wide: wide),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: Pager(
              page: paged.page,
              totalPages: paged.totalPages,
              onPageChanged: (int p) =>
                  ref.read(groupedFiltersProvider.notifier).setPage(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    Widget h(String s, {int flex = 0, double? width}) {
      final Widget t = Text(s, style: AppTextStyles.sectionLabel);
      if (width != null) return SizedBox(width: width, child: t);
      return Expanded(flex: flex, child: t);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: <Widget>[
          h('Tablet / Manufacturer', flex: 3),
          h('Clients (expiring)', flex: 3),
          h('Batches', width: 70),
          h('Qty', width: 60),
          h('Expiring', width: 110),
          h('Expired', width: 110),
          h('Earliest expiry', flex: 2),
          h('', width: 48),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.wide});
  final TabletGroup group;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      child: wide ? _wide(context) : _narrow(context),
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(flex: 3, child: _nameCol()),
        Expanded(
          flex: 3,
          child: Text(
            group.clientsWithExpiring.isEmpty
                ? '—'
                : group.clientsWithExpiring.join(', '),
            style: AppTextStyles.body,
          ),
        ),
        SizedBox(width: 70, child: Text('${group.batches}', style: AppTextStyles.bodyStrong)),
        SizedBox(width: 60, child: Text('${group.totalQuantity}', style: AppTextStyles.bodyStrong)),
        SizedBox(
          width: 110,
          child: group.expiringCount > 0
              ? Pill(
                  label:
                      '${group.expiringCount} · ${group.expiringUnits}u',
                  tone: PillTone.warning)
              : Text('—', style: AppTextStyles.bodyMuted),
        ),
        SizedBox(
          width: 110,
          child: group.expiredCount > 0
              ? Pill(
                  label:
                      '${group.expiredCount} · ${group.expiredUnits}u',
                  tone: PillTone.danger)
              : Text('—', style: AppTextStyles.bodyMuted),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(formatDmy(group.earliestExpiry),
                  style: AppTextStyles.bodyStrong),
              Text(dueInDaysLabel(group.earliestExpiry),
                  style: AppTextStyles.small),
            ],
          ),
        ),
        SizedBox(
          width: 48,
          child: IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 18),
            tooltip: 'View on dashboard',
            onPressed: () => context.go(
                '/?tablet=${Uri.encodeQueryComponent(group.tabletName)}&mfr=${Uri.encodeQueryComponent(group.manufacturer)}'),
          ),
        ),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _nameCol()),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              onPressed: () => context.go(
                  '/?tablet=${Uri.encodeQueryComponent(group.tabletName)}&mfr=${Uri.encodeQueryComponent(group.manufacturer)}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            if (group.expiringCount > 0)
              Pill(
                  label:
                      'Expiring ${group.expiringCount} · ${group.expiringUnits}u',
                  tone: PillTone.warning),
            if (group.expiredCount > 0)
              Pill(
                  label:
                      'Expired ${group.expiredCount} · ${group.expiredUnits}u',
                  tone: PillTone.danger),
            Pill(label: '${group.batches} batches', tone: PillTone.info),
            Pill(label: '${group.totalQuantity}u total', tone: PillTone.neutral),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Earliest expiry ${formatDmy(group.earliestExpiry)} · ${dueInDaysLabel(group.earliestExpiry)}',
          style: AppTextStyles.small,
        ),
        if (group.clientsWithExpiring.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text('Clients (expiring): ${group.clientsWithExpiring.join(", ")}',
              style: AppTextStyles.small),
        ],
      ],
    );
  }

  Widget _nameCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(group.tabletName, style: AppTextStyles.bodyStrong),
        Text(group.manufacturer, style: AppTextStyles.small),
      ],
    );
  }
}
