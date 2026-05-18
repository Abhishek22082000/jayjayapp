import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatusFilter { all, active, expiring, expired }

@immutable
class TabletFilters {
  final String search;
  final StatusFilter status;
  final String? tabletName; // hidden filter from drill-down
  final String? manufacturer; // hidden filter from drill-down
  final int page; // 1-based

  const TabletFilters({
    this.search = '',
    this.status = StatusFilter.all,
    this.tabletName,
    this.manufacturer,
    this.page = 1,
  });

  TabletFilters copyWith({
    String? search,
    StatusFilter? status,
    String? tabletName,
    bool clearTabletName = false,
    String? manufacturer,
    bool clearManufacturer = false,
    int? page,
  }) {
    return TabletFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      tabletName: clearTabletName ? null : (tabletName ?? this.tabletName),
      manufacturer: clearManufacturer ? null : (manufacturer ?? this.manufacturer),
      page: page ?? this.page,
    );
  }
}

class TabletFiltersNotifier extends StateNotifier<TabletFilters> {
  TabletFiltersNotifier() : super(const TabletFilters());

  void setSearch(String value) => state = state.copyWith(search: value, page: 1);
  void setStatus(StatusFilter s) => state = state.copyWith(status: s, page: 1);
  void setHidden({String? tablet, String? mfr}) {
    state = state.copyWith(
      tabletName: tablet,
      clearTabletName: tablet == null,
      manufacturer: mfr,
      clearManufacturer: mfr == null,
      page: 1,
    );
  }
  void setPage(int p) => state = state.copyWith(page: p);
  void reset() => state = const TabletFilters();
}

final filtersProvider =
    StateNotifierProvider<TabletFiltersNotifier, TabletFilters>((Ref ref) {
  return TabletFiltersNotifier();
});

enum GroupedFilter { expiringSoon, hasExpired, needsAttention, all }

@immutable
class GroupedFilters {
  final String search;
  final GroupedFilter filter;
  final int page;
  const GroupedFilters({
    this.search = '',
    this.filter = GroupedFilter.expiringSoon,
    this.page = 1,
  });
  GroupedFilters copyWith({String? search, GroupedFilter? filter, int? page}) {
    return GroupedFilters(
      search: search ?? this.search,
      filter: filter ?? this.filter,
      page: page ?? this.page,
    );
  }
}

class GroupedFiltersNotifier extends StateNotifier<GroupedFilters> {
  GroupedFiltersNotifier() : super(const GroupedFilters());
  void setSearch(String v) => state = state.copyWith(search: v, page: 1);
  void setFilter(GroupedFilter f) => state = state.copyWith(filter: f, page: 1);
  void setPage(int p) => state = state.copyWith(page: p);
  void reset() => state = const GroupedFilters();
}

final groupedFiltersProvider =
    StateNotifierProvider<GroupedFiltersNotifier, GroupedFilters>((Ref ref) {
  return GroupedFiltersNotifier();
});
