import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

/// Root widget aplikasi SightAssist.
///
/// Mengkonfigurasi theme, routes, dan title.
class SightAssistApp extends StatelessWidget {
  const SightAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRouter.home,
      routes: AppRouter.routes,
    );
  }
}
