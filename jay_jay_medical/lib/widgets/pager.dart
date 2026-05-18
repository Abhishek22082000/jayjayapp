import 'package:flutter/material.dart';

import '../app/theme.dart';

class Pager extends StatelessWidget {
  const Pager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  List<Object> _pageItems() {
    // Returns ints for page numbers and the string "…" for ellipses.
    final List<Object> out = <Object>[];
    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        out.add(i);
      }
      return out;
    }
    out.add(1);
    final int start = (page - 1).clamp(2, totalPages - 3);
    final int end = (page + 1).clamp(4, totalPages - 1);
    if (start > 2) out.add('…');
    for (int i = start; i <= end; i++) {
      out.add(i);
    }
    if (end < totalPages - 1) out.add('…');
    out.add(totalPages);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final List<Object> items = _pageItems();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _chevron(Icons.chevron_left, page > 1 ? () => onPageChanged(page - 1) : null),
        for (final Object it in items)
          if (it is int)
            _numberButton(it)
          else
            const _Ellipsis(),
        _chevron(Icons.chevron_right,
            page < totalPages ? () => onPageChanged(page + 1) : null),
      ],
    );
  }

  Widget _chevron(IconData icon, VoidCallback? onTap) {
    return _PagerCell(
      onTap: onTap,
      child: Icon(icon, size: 18, color: AppColors.textMuted),
    );
  }

  Widget _numberButton(int n) {
    final bool active = n == page;
    return _PagerCell(
      filled: active,
      onTap: active ? null : () => onPageChanged(n),
      child: Text('$n',
          style: TextStyle(
            color: active ? Colors.white : AppColors.text,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          )),
    );
  }
}

class _PagerCell extends StatelessWidget {
  const _PagerCell({this.onTap, required this.child, this.filled = false});
  final VoidCallback? onTap;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.surface,
            border: Border.all(
                color: filled ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(8),
            boxShadow: filled ? AppShadows.soft : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Ellipsis extends StatelessWidget {
  const _Ellipsis();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 34,
      child: Center(
        child: Text('…',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
      ),
    );
  }
}
