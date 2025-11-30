import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_settings.dart';

/// Repository for managing game settings persistence
class SettingsRepository {
  static const String _settingsKey = 'game_settings';

  /// Load game settings from persistent storage
  Future<GameSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString == null) {
        if (kDebugMode) {
          debugPrint('[SettingsRepository] No saved settings found, using defaults');
        }
        return const GameSettings(); // Return default settings
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final settings = GameSettings.fromJson(json);

      if (kDebugMode) {
        debugPrint('[SettingsRepository] Settings loaded successfully');
      }

      return settings;
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('[SettingsRepository] ERROR: Invalid JSON format in saved settings: $e');
        debugPrint('[SettingsRepository] Falling back to default settings');
      }
      return const GameSettings();
    } catch (e, stackTrace) {
      // If there's any error loading settings, return defaults
      if (kDebugMode) {
        debugPrint('[SettingsRepository] ERROR loading settings: $e');
        debugPrint('[SettingsRepository] Stack trace: $stackTrace');
        debugPrint('[SettingsRepository] Falling back to default settings');
      }
      return const GameSettings();
    }
  }

  /// Save game settings to persistent storage
  Future<void> saveSettings(GameSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, jsonString);

      if (kDebugMode) {
        debugPrint('[SettingsRepository] Settings saved successfully');
      }
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('[SettingsRepository] ERROR: Failed to encode settings to JSON: $e');
      }
      // Silently fail - settings just won't persist
    } catch (e, stackTrace) {
      // Silently fail - settings just won't persist
      if (kDebugMode) {
        debugPrint('[SettingsRepository] ERROR saving settings: $e');
        debugPrint('[SettingsRepository] Stack trace: $stackTrace');
      }
    }
  }
}
