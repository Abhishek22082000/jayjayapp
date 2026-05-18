import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../config.dart';
import '../providers/tablets_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _routed = false;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasBaseUrl) {
      return _ConfigError();
    }
    final AsyncValue<Object> async = ref.watch(tabletsStreamProvider);

    if (async.hasValue && !_routed) {
      _routed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/');
      });
    }

    if (async.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.dangerSoft,
            content: Text(
              'API unreachable: ${async.error}',
              style: const TextStyle(color: AppColors.dangerText),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.dangerText,
              onPressed: () => ref.invalidate(tabletsStreamProvider),
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 180,
              height: 180,
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (BuildContext ctx, Object err, _) {
                  // Fallback: gradient capsule if the asset is missing.
                  return Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppShadows.soft,
                    ),
                    child: const Icon(Icons.medication_outlined,
                        color: Colors.white, size: 44),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('Tablet records & expiry', style: AppTextStyles.bodyMuted),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.error_outline,
                    color: AppColors.dangerText, size: 36),
                const SizedBox(height: 10),
                Text('Configuration missing',
                    style: AppTextStyles.heading),
                const SizedBox(height: 6),
                Text(
                  'API_BASE_URL was not provided at build time. Re-run the app with:',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    'flutter run --dart-define=API_BASE_URL=https://your-app.vercel.app',
                    style: AppTextStyles.batchMono,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
