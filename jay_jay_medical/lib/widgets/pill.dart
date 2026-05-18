import 'package:flutter/material.dart';

import '../app/theme.dart';

enum PillTone { success, warning, danger, info, neutral }

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  ({Color bg, Color fg, Color dot}) get _palette {
    switch (tone) {
      case PillTone.success:
        return (
          bg: AppColors.successSoft,
          fg: AppColors.successText,
          dot: AppColors.success,
        );
      case PillTone.warning:
        return (
          bg: AppColors.warningSoft,
          fg: AppColors.warningText,
          dot: AppColors.warning,
        );
      case PillTone.danger:
        return (
          bg: AppColors.dangerSoft,
          fg: AppColors.dangerText,
          dot: AppColors.danger,
        );
      case PillTone.info:
        return (
          bg: AppColors.primarySoft,
          fg: AppColors.primaryDark,
          dot: AppColors.primary,
        );
      case PillTone.neutral:
        return (
          bg: AppColors.surfaceAlt,
          fg: AppColors.textMuted,
          dot: AppColors.textSoft,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: p.fg),
            const SizedBox(width: 6),
          ] else ...<Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: p.dot,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppTextStyles.pill.copyWith(color: p.fg)),
        ],
      ),
    );
  }
}
