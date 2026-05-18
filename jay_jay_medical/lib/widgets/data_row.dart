import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/tablet.dart';
import '../utils/date_utils.dart';
import '../utils/status_utils.dart';
import 'pill.dart';

Color rowTintFor(TabletStatus s) {
  switch (s) {
    case TabletStatus.expiring:
      return AppColors.rowExpiringTint;
    case TabletStatus.expired:
      return AppColors.rowExpiredTint;
    case TabletStatus.active:
      return AppColors.surface;
  }
}

Pill statusPillFor(TabletStatus s) {
  switch (s) {
    case TabletStatus.active:
      return const Pill(label: 'Active', tone: PillTone.success);
    case TabletStatus.expiring:
      return const Pill(label: 'Expiring soon', tone: PillTone.warning);
    case TabletStatus.expired:
      return const Pill(label: 'Expired', tone: PillTone.danger);
  }
}

class TabletDataRow extends StatefulWidget {
  const TabletDataRow({
    super.key,
    required this.index,
    required this.tablet,
    required this.onEdit,
    required this.onDelete,
    required this.isWide,
  });

  final int index;
  final Tablet tablet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isWide;

  @override
  State<TabletDataRow> createState() => _TabletDataRowState();
}

class _TabletDataRowState extends State<TabletDataRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Tablet t = widget.tablet;
    final TabletStatus s = t.status;
    final Color tint = rowTintFor(s);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.border),
          boxShadow: _hover ? AppShadows.soft : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        child: widget.isWide ? _wide(context, t, s) : _narrow(context, t, s),
      ),
    );
  }

  Widget _wide(BuildContext context, Tablet t, TabletStatus s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 32,
          child: Text('${widget.index}',
              style: AppTextStyles.bodyMuted, textAlign: TextAlign.left),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.tabletName, style: AppTextStyles.bodyStrong),
              Text(t.manufacturer, style: AppTextStyles.small),
            ],
          ),
        ),
        Expanded(flex: 2, child: Text(t.clientName, style: AppTextStyles.body)),
        Expanded(flex: 2, child: _batchChip(t.batchNumber)),
        SizedBox(
            width: 60,
            child: Text('${t.quantity}',
                style: AppTextStyles.bodyStrong, textAlign: TextAlign.right)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (t.manufacturingDate != null)
                Text('Mfg ${formatDmy(t.manufacturingDate!)}',
                    style: AppTextStyles.small),
              Text('Start ${formatDmy(t.startDate)}',
                  style: AppTextStyles.small),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(formatDmy(t.endDate), style: AppTextStyles.bodyStrong),
              Text(dueInDaysLabel(t.endDate),
                  style: AppTextStyles.small.copyWith(
                    color: s == TabletStatus.expired
                        ? AppColors.dangerText
                        : (s == TabletStatus.expiring
                            ? AppColors.warningText
                            : AppColors.textMuted),
                  )),
            ],
          ),
        ),
        SizedBox(width: 140, child: Align(alignment: Alignment.centerLeft, child: statusPillFor(s))),
        _actions(),
      ],
    );
  }

  Widget _narrow(BuildContext context, Tablet t, TabletStatus s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(t.tabletName, style: AppTextStyles.bodyStrong),
                  Text(t.manufacturer, style: AppTextStyles.small),
                ],
              ),
            ),
            statusPillFor(s),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: <Widget>[
            _kv('Client', t.clientName),
            _kv('Qty', '${t.quantity}'),
            _kv('Expiry',
                '${formatDmy(t.endDate)} · ${dueInDaysLabel(t.endDate)}'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _batchChip(t.batchNumber),
            const Spacer(),
            _actions(),
          ],
        ),
      ],
    );
  }

  Widget _batchChip(String batch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('#$batch', style: AppTextStyles.batchMono),
    );
  }

  Widget _kv(String k, String v) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
        children: <InlineSpan>[
          TextSpan(text: '$k: '),
          TextSpan(
              text: v,
              style: AppTextStyles.small.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: widget.onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppColors.primaryDark,
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: widget.onDelete,
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColors.danger,
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
