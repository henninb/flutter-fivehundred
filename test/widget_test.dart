// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cribbage/src/app.dart';
import 'package:cribbage/src/game/engine/game_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FiveHundredApp renders a MaterialApp', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final engine = GameEngine();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: engine,
        child: const FiveHundredApp(),
      ),
    );

    // Allow async initialization inside the app to complete
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
