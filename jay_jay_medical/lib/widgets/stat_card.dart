import 'package:flutter/material.dart';

import '../app/theme.dart';

enum StatTone { total, active, expiring, expired }

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final StatTone tone;

  ({Color accent, Color chipBg, Color chipFg}) get _p {
    switch (tone) {
      case StatTone.total:
        return (
          accent: AppColors.primary,
          chipBg: AppColors.primarySoft,
          chipFg: AppColors.primaryDark,
        );
      case StatTone.active:
        return (
          accent: AppColors.success,
          chipBg: AppColors.successSoft,
          chipFg: AppColors.successText,
        );
      case StatTone.expiring:
        return (
          accent: AppColors.warning,
          chipBg: AppColors.warningSoft,
          chipFg: AppColors.warningText,
        );
      case StatTone.expired:
        return (
          accent: AppColors.danger,
          chipBg: AppColors.dangerSoft,
          chipFg: AppColors.dangerText,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: AppRadius.cardR,
                  bottomLeft: AppRadius.cardR,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.chipBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: p.chipFg, size: 20),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(value, style: AppTextStyles.statNumber),
                    const SizedBox(height: 4),
                    Text(label.toUpperCase(),
                        style: AppTextStyles.sectionLabel),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AppTextStyles.small),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
