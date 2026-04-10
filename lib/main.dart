import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/game/engine/game_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final engine = GameEngine();
  await engine.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: engine,
      child: const FiveHundredApp(),
    ),
  );
}
