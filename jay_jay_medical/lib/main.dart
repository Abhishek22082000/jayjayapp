import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: JayJayMedicalApp()));
}

class JayJayMedicalApp extends StatelessWidget {
  const JayJayMedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'JJ Medical',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: buildRouter(),
    );
  }
}
