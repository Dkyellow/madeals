import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/db/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/listings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // SQLite (`madeals.db`) is the single source of truth — init + seed before UI.
  final initialListings = await DatabaseHelper.instance.getListings();

  runApp(
    ProviderScope(
      overrides: [
        initialListingsProvider.overrideWithValue(initialListings),
      ],
      child: const MaDealsApp(),
    ),
  );
}

class MaDealsApp extends StatelessWidget {
  const MaDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MADEALS - Zimbabwe P2P Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
