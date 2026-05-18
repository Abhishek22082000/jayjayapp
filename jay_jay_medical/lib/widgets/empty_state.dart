import 'package:flutter/material.dart';

import '../app/theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.cta,
  });

  final IconData icon;
  final String message;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 56, color: AppColors.textSoft),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          if (cta != null) ...<Widget>[
            const SizedBox(height: 16),
            cta!,
          ],
        ],
      ),
    );
  }
}
