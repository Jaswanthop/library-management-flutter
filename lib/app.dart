import 'package:flutter/material.dart';

import 'data/library_store.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

/// Root widget: owns the store and the theme preference.
class ShelfwiseApp extends StatefulWidget {
  const ShelfwiseApp({super.key, this.store});

  /// Optional injectable store (used by tests).
  final LibraryStore? store;

  @override
  State<ShelfwiseApp> createState() => _ShelfwiseAppState();
}

class _ShelfwiseAppState extends State<ShelfwiseApp> {
  late final LibraryStore _store = widget.store ?? LibraryStore.seeded();
  final ValueNotifier<ThemeMode> _themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LibraryScope(
      store: _store,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (BuildContext context, ThemeMode mode, Widget? _) {
          return MaterialApp(
            title: 'Shelfwise · Library Management',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            home: AppShell(themeMode: _themeMode),
          );
        },
      ),
    );
  }
}
