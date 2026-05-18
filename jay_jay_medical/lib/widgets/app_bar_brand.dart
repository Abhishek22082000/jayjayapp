import 'package:flutter/material.dart';

import '../app/theme.dart';

class AppBarBrand extends StatelessWidget implements PreferredSizeWidget {
  const AppBarBrand({super.key, this.actions, this.compactActions});

  /// Actions shown on screens ≥ 480 px wide (text+icon buttons).
  final List<Widget>? actions;

  /// Actions shown on screens < 480 px wide (typically icon-only).
  /// Falls back to [actions] when null.
  final List<Widget>? compactActions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder:
              (BuildContext ctx, BoxConstraints c) {
            final bool narrow = c.maxWidth < 480;
            final List<Widget> shown =
                (narrow && compactActions != null) ? compactActions! : (actions ?? const <Widget>[]);
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 12 : 16,
                vertical: 8,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'JJ Medical',
                          style: AppTextStyles.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!narrow)
                          Text(
                            'Tablet records & expiry',
                            style: AppTextStyles.brandSub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  ...shown,
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
