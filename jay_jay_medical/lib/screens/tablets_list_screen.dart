import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../models/tablet.dart';
import '../providers/filters_provider.dart';
import '../providers/tablets_providers.dart';
import '../services/tablets_repository.dart';
import '../widgets/app_bar_brand.dart';
import '../widgets/brand_gradient_button.dart';
import '../widgets/data_row.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_card.dart';
import '../widgets/pager.dart';

// All tablet records with filters and pagination. Reachable from:
//   • dashboard stat-card taps  — passes ?status=
//   • grouped view drill-down   — passes ?tablet= and ?mfr=
//   • a "View all" link or scan FAB if added later
//
// statusFilter / tabletFilter / mfrFilter come from query params and seed
// the shared filtersProvider on first frame. After that the user can edit
// filters in-screen; navigating in again with the same params re-seeds.
class TabletsListScreen extends ConsumerStatefulWidget {
  const TabletsListScreen({
    super.key,
    this.statusFilter,
    this.tabletFilter,
    this.mfrFilter,
  });

  final String? statusFilter;
  final String? tabletFilter;
  final String? mfrFilter;

  @override
  ConsumerState<TabletsListScreen> createState() => _TabletsListScreenState();
}

class _TabletsListScreenState extends ConsumerState<TabletsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyQueryParams();
      _searchCtrl.text = ref.read(filtersProvider).search;
    });
  }

  @override
  void didUpdateWidget(covariant TabletsListScreen old) {
    super.didUpdateWidget(old);
    if (old.statusFilter != widget.statusFilter ||
        old.tabletFilter != widget.tabletFilter ||
        old.mfrFilter != widget.mfrFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyQueryParams());
    }
  }

  void _applyQueryParams() {
    final TabletFiltersNotifier n = ref.read(filtersProvider.notifier);
    n.setHidden(tablet: widget.tabletFilter, mfr: widget.mfrFilter);
    n.setStatus(_statusFromQuery(widget.statusFilter));
  }

  StatusFilter _statusFromQuery(String? q) {
    switch (q?.toLowerCase()) {
      case 'active':
        return StatusFilter.active;
      case 'expiring':
        return StatusFilter.expiring;
      case 'expired':
        return StatusFilter.expired;
      case 'all':
      case null:
      case '':
        return StatusFilter.all;
      default:
        return StatusFilter.all;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Tablet>> async = ref.watch(tabletsStreamProvider);
    final PagedTablets paged = ref.watch(filteredTabletsProvider);

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
            tooltip: 'Dashboard',
            icon: const Icon(Icons.dashboard_outlined),
            color: AppColors.primaryDark,
            onPressed: () => context.go('/'),
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
                  Text('Tablet records', style: AppTextStyles.heading),
                  const SizedBox(height: 14),
                  _filtersCard(),
                  const SizedBox(height: 14),
                  if (paged.totalCount == 0)
                    const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message:
                          'No tablets match these filters. Try resetting or add a new tablet.',
                    )
                  else
                    _listCard(paged, wide),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _filtersCard() {
    final TabletFilters f = ref.watch(filtersProvider);
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
                decoration: InputDecoration(
                  hintText: 'Search tablet, client, batch, manufacturer',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: f.search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(filtersProvider.notifier).setSearch('');
                          },
                        ),
                ),
                onChanged: (String v) =>
                    ref.read(filtersProvider.notifier).setSearch(v),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<StatusFilter>(
                key: ValueKey<StatusFilter>(f.status),
                initialValue: f.status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const <DropdownMenuItem<StatusFilter>>[
                  DropdownMenuItem<StatusFilter>(
                      value: StatusFilter.all, child: Text('All')),
                  DropdownMenuItem<StatusFilter>(
                      value: StatusFilter.active, child: Text('Active')),
                  DropdownMenuItem<StatusFilter>(
                      value: StatusFilter.expiring,
                      child: Text('Expiring ≤7 days')),
                  DropdownMenuItem<StatusFilter>(
                      value: StatusFilter.expired, child: Text('Expired')),
                ],
                onChanged: (StatusFilter? v) {
                  if (v != null) {
                    ref.read(filtersProvider.notifier).setStatus(v);
                  }
                },
              ),
            ),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                ref.read(filtersProvider.notifier).reset();
                context.go('/tablets');
              },
              child: const Text('Reset'),
            ),
          ],
        ),
        if (f.tabletName != null || f.manufacturer != null) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: <Widget>[
              if (f.tabletName != null)
                Chip(
                  label: Text('Tablet: ${f.tabletName}'),
                  onDeleted: () {
                    ref.read(filtersProvider.notifier).setHidden(
                          tablet: null,
                          mfr: f.manufacturer,
                        );
                  },
                ),
              if (f.manufacturer != null)
                Chip(
                  label: Text('Mfr: ${f.manufacturer}'),
                  onDeleted: () {
                    ref.read(filtersProvider.notifier).setHidden(
                          tablet: f.tabletName,
                          mfr: null,
                        );
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _listCard(PagedTablets paged, bool wide) {
    final TabletsRepository repo = ref.read(tabletsRepositoryProvider);
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
              Text('TABLET RECORDS', style: AppTextStyles.sectionLabel),
              const Spacer(),
              Text(
                'Showing ${paged.firstRowIndex}–${paged.lastRowIndex} of ${paged.totalCount}',
                style: AppTextStyles.small,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (wide) _headerRow(),
          if (wide) const SizedBox(height: 6),
          for (int i = 0; i < paged.pageItems.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.control),
              onTap: () =>
                  context.push('/tablets/${paged.pageItems[i].id}'),
              child: TabletDataRow(
                index: paged.firstRowIndex + i,
                tablet: paged.pageItems[i],
                isWide: wide,
                onEdit: () =>
                    context.push('/tablets/${paged.pageItems[i].id}/edit'),
                onDelete: () => _confirmDelete(repo, paged.pageItems[i]),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: Pager(
              page: paged.page,
              totalPages: paged.totalPages,
              onPageChanged: (int p) =>
                  ref.read(filtersProvider.notifier).setPage(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    Widget h(String s, {int flex = 0, double? width, TextAlign? align}) {
      final Widget t = Text(s,
          style: AppTextStyles.sectionLabel,
          textAlign: align ?? TextAlign.left);
      if (width != null) return SizedBox(width: width, child: t);
      return Expanded(flex: flex, child: t);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: <Widget>[
          h('#', width: 32),
          h('Tablet', flex: 3),
          h('Client', flex: 2),
          h('Batch', flex: 2),
          h('Qty', width: 60, align: TextAlign.right),
          const SizedBox(width: 12),
          h('Mfg / Start', flex: 2),
          h('Expiry', flex: 2),
          h('Status', width: 140),
          h('Actions', width: 100),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(TabletsRepository repo, Tablet t) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete tablet record?'),
        content: Text(
            '${t.tabletName} · ${t.clientName} · batch #${t.batchNumber} will be removed.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await repo.delete(t.id);
      ref.invalidate(tabletsStreamProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dangerSoft,
          content: Text('Deleted ${t.tabletName}',
              style: const TextStyle(color: AppColors.dangerText)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}
