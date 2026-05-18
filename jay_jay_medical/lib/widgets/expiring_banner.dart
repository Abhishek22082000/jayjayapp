import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/tablet.dart';
import '../utils/date_utils.dart';
import 'pill.dart';

class ExpiringBanner extends StatelessWidget {
  const ExpiringBanner({
    super.key,
    required this.items,
    required this.onSeeByTablet,
  });

  final List<Tablet> items;
  final VoidCallback onSeeByTablet;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warningText, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${items.length} batches expiring within the next 7 days',
                  style: TextStyle(
                    color: AppColors.warningText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeByTablet,
                child: const Text('See by tablet →'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final Tablet t in items)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Pill(
                      tone: PillTone.warning,
                      label:
                          '${t.tabletName} (${t.manufacturer}) · ${t.clientName} · ${t.quantity}u — ${dueInDaysLabel(t.endDate)}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
