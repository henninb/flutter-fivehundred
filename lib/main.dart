import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/game/engine/game_engine.dart';
import 'src/services/game_persistence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle SharedPreferences initialization with error handling
  late final GameEngine engine;

  try {
    final prefs = await SharedPreferences.getInstance();
    final persistence = SharedPrefsPersistence(prefs);
    engine = GameEngine(persistence: persistence);
    await engine.initialize();

    if (kDebugMode) {
      debugPrint('[Main] App initialized successfully with persistence');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('[Main] ERROR initializing SharedPreferences: $e');
      debugPrint('[Main] Stack trace: $stackTrace');
      debugPrint('[Main] Continuing without persistence...');
    }

    // Fallback: Initialize engine without persistence
    engine = GameEngine(persistence: null);
    await engine.initialize();
  }

  runApp(
    ChangeNotifierProvider.value(
      value: engine,
      child: const FiveHundredApp(),
    ),
  );
}
