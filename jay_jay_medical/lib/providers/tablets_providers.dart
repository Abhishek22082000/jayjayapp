import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/common_tablets.dart';
import '../models/tablet.dart';
import '../services/tablets_repository.dart';
import '../utils/grouping.dart';
import '../utils/status_utils.dart';
import 'filters_provider.dart';

const int kPageSize = 15;
const Duration kPollInterval = Duration(seconds: 10);

final tabletsRepositoryProvider = Provider<TabletsRepository>((Ref ref) {
  final TabletsRepository repo = TabletsRepository();
  ref.onDispose(() {});
  return repo;
});

// Polls the Vercel API every 10 seconds and emits the latest list.
// Screens can `ref.invalidate(tabletsStreamProvider)` after a mutation
// to force an immediate refresh.
//
// TODO: switch to Server-Sent Events or WebSocket if multi-device sync
// becomes required; polling is sufficient for a single-user shop.
final tabletsStreamProvider = StreamProvider<List<Tablet>>((Ref ref) async* {
  final TabletsRepository repo = ref.watch(tabletsRepositoryProvider);
  bool active = true;
  ref.onDispose(() => active = false);
  while (active) {
    try {
      yield await repo.fetchAll();
    } catch (e) {
      yield* Stream<List<Tablet>>.error(e);
    }
    if (!active) break;
    await Future<void>.delayed(kPollInterval);
  }
});

@immutable
class DashboardStats {
  final int total;
  final int totalUnits;
  final int active;
  final int expiring;
  final int expired;
  const DashboardStats({
    required this.total,
    required this.totalUnits,
    required this.active,
    required this.expiring,
    required this.expired,
  });
}

final statsProvider = Provider<DashboardStats>((Ref ref) {
  final AsyncValue<List<Tablet>> async = ref.watch(tabletsStreamProvider);
  final List<Tablet> all = async.maybeWhen<List<Tablet>>(
    data: (List<Tablet> v) => v,
    orElse: () => const <Tablet>[],
  );
  int active = 0, expiring = 0, expired = 0, totalUnits = 0;
  for (final Tablet t in all) {
    totalUnits += t.quantity;
    switch (t.status) {
      case TabletStatus.active:
        active++;
        break;
      case TabletStatus.expiring:
        expiring++;
        break;
      case TabletStatus.expired:
        expired++;
        break;
    }
  }
  return DashboardStats(
    total: all.length,
    totalUnits: totalUnits,
    active: active,
    expiring: expiring,
    expired: expired,
  );
});

@immutable
class PagedTablets {
  final List<Tablet> pageItems;
  final int totalCount;
  final int page;
  final int pageSize;
  const PagedTablets({
    required this.pageItems,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });
  int get totalPages => (totalCount / pageSize).ceil().clamp(1, 1 << 30);
  int get firstRowIndex => totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
  int get lastRowIndex {
    final int end = page * pageSize;
    return end > totalCount ? totalCount : end;
  }
}

bool _matchesSearch(Tablet t, String q) {
  if (q.isEmpty) return true;
  final String n = q.toLowerCase();
  return t.tabletName.toLowerCase().contains(n) ||
      t.clientName.toLowerCase().contains(n) ||
      t.batchNumber.toLowerCase().contains(n) ||
      t.manufacturer.toLowerCase().contains(n);
}

final filteredTabletsProvider = Provider<PagedTablets>((Ref ref) {
  final AsyncValue<List<Tablet>> async = ref.watch(tabletsStreamProvider);
  final TabletFilters f = ref.watch(filtersProvider);
  final List<Tablet> all = async.maybeWhen<List<Tablet>>(
    data: (List<Tablet> v) => v,
    orElse: () => const <Tablet>[],
  );
  final List<Tablet> filtered = all.where((Tablet t) {
    if (!_matchesSearch(t, f.search.trim())) return false;
    if (f.tabletName != null &&
        t.tabletName.toLowerCase() != f.tabletName!.toLowerCase()) {
      return false;
    }
    if (f.manufacturer != null &&
        t.manufacturer.toLowerCase() != f.manufacturer!.toLowerCase()) {
      return false;
    }
    switch (f.status) {
      case StatusFilter.all:
        return true;
      case StatusFilter.active:
        return t.status == TabletStatus.active;
      case StatusFilter.expiring:
        return t.status == TabletStatus.expiring;
      case StatusFilter.expired:
        return t.status == TabletStatus.expired;
    }
  }).toList();

  // Sort: endDate ASC, id DESC for deterministic order
  filtered.sort((Tablet a, Tablet b) {
    final int byDate = a.endDate.compareTo(b.endDate);
    if (byDate != 0) return byDate;
    return b.id.compareTo(a.id);
  });

  final int total = filtered.length;
  final int totalPages = (total / kPageSize).ceil().clamp(1, 1 << 30);
  final int page = f.page.clamp(1, totalPages);
  final int start = (page - 1) * kPageSize;
  final int end = (start + kPageSize) > total ? total : (start + kPageSize);
  return PagedTablets(
    pageItems: filtered.sublist(start, end),
    totalCount: total,
    page: page,
    pageSize: kPageSize,
  );
});

final expiringSoonProvider = Provider<List<Tablet>>((Ref ref) {
  final AsyncValue<List<Tablet>> async = ref.watch(tabletsStreamProvider);
  final List<Tablet> all = async.maybeWhen<List<Tablet>>(
    data: (List<Tablet> v) => v,
    orElse: () => const <Tablet>[],
  );
  final List<Tablet> r = all
      .where((Tablet t) => t.status == TabletStatus.expiring)
      .toList();
  r.sort((Tablet a, Tablet b) => a.endDate.compareTo(b.endDate));
  return r;
});

@immutable
class AutocompleteSets {
  final Set<String> tabletNames;
  final Set<String> manufacturers;
  const AutocompleteSets(this.tabletNames, this.manufacturers);
}

final autocompleteValuesProvider = Provider<AutocompleteSets>((Ref ref) {
  final AsyncValue<List<Tablet>> async = ref.watch(tabletsStreamProvider);
  final List<Tablet> all = async.maybeWhen<List<Tablet>>(
    data: (List<Tablet> v) => v,
    orElse: () => const <Tablet>[],
  );
  // Merge curated seed lists with whatever the user has already entered
  // so suggestions work from day one on an empty database.
  final Set<String> tabletNames = <String>{
    ...kCommonTablets,
    ...all.map((Tablet t) => t.tabletName).where((String s) => s.isNotEmpty),
  };
  final Set<String> manufacturers = <String>{
    ...kCommonManufacturers,
    ...all.map((Tablet t) => t.manufacturer).where((String s) => s.isNotEmpty),
  };
  return AutocompleteSets(tabletNames, manufacturers);
});

// ───── Grouped view ─────

@immutable
class PagedGroups {
  final List<TabletGroup> pageItems;
  final int totalCount;
  final int page;
  final int pageSize;
  const PagedGroups({
    required this.pageItems,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });
  int get totalPages => (totalCount / pageSize).ceil().clamp(1, 1 << 30);
  int get firstRowIndex => totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
  int get lastRowIndex {
    final int end = page * pageSize;
    return end > totalCount ? totalCount : end;
  }
}

final groupedTabletsProvider = Provider<PagedGroups>((Ref ref) {
  final AsyncValue<List<Tablet>> async = ref.watch(tabletsStreamProvider);
  final GroupedFilters gf = ref.watch(groupedFiltersProvider);
  final List<Tablet> all = async.maybeWhen<List<Tablet>>(
    data: (List<Tablet> v) => v,
    orElse: () => const <Tablet>[],
  );
  final List<TabletGroup> groups = groupTablets(all);
  final List<TabletGroup> filtered = groups.where((TabletGroup g) {
    if (gf.search.trim().isNotEmpty) {
      final String n = gf.search.trim().toLowerCase();
      if (!g.tabletName.toLowerCase().contains(n) &&
          !g.manufacturer.toLowerCase().contains(n)) {
        return false;
      }
    }
    switch (gf.filter) {
      case GroupedFilter.expiringSoon:
        return g.hasExpiring;
      case GroupedFilter.hasExpired:
        return g.hasExpired;
      case GroupedFilter.needsAttention:
        return g.needsAttention;
      case GroupedFilter.all:
        return true;
    }
  }).toList();

  final int total = filtered.length;
  final int totalPages = (total / kPageSize).ceil().clamp(1, 1 << 30);
  final int page = gf.page.clamp(1, totalPages);
  final int start = (page - 1) * kPageSize;
  final int end = (start + kPageSize) > total ? total : (start + kPageSize);
  return PagedGroups(
    pageItems: filtered.sublist(start, end),
    totalCount: total,
    page: page,
    pageSize: kPageSize,
  );
});
