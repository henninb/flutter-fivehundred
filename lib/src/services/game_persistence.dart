import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/models/card.dart';

class StoredStats {
  const StoredStats({
    required this.gamesWon,
    required this.gamesLost,
    required this.skunksFor,
    required this.skunksAgainst,
    required this.doubleSkunksFor,
    required this.doubleSkunksAgainst,
  });

  final int gamesWon;
  final int gamesLost;
  final int skunksFor;
  final int skunksAgainst;
  final int doubleSkunksFor;
  final int doubleSkunksAgainst;
}

class CutCards {
  const CutCards({required this.player, required this.opponent});

  final PlayingCard player;
  final PlayingCard opponent;
}

class PlayerNames {
  const PlayerNames({required this.playerName, required this.opponentName});

  final String playerName;
  final String opponentName;
}

abstract class GamePersistence {
  StoredStats? loadStats();
  void saveStats({
    required int gamesWon,
    required int gamesLost,
    required int skunksFor,
    required int skunksAgainst,
    required int doubleSkunksFor,
    required int doubleSkunksAgainst,
  });

  CutCards? loadCutCards();
  void saveCutCards(PlayingCard player, PlayingCard opponent);

  PlayerNames? loadPlayerNames();
  void savePlayerNames({required String playerName, required String opponentName});
}

class SharedPrefsPersistence implements GamePersistence {
  SharedPrefsPersistence(this._prefs);

  final SharedPreferences _prefs;

  static const _gamesWonKey = 'gamesWon';
  static const _gamesLostKey = 'gamesLost';
  static const _skunksForKey = 'skunksFor';
  static const _skunksAgainstKey = 'skunksAgainst';
  static const _doubleSkunksForKey = 'doubleSkunksFor';
  static const _doubleSkunksAgainstKey = 'doubleSkunksAgainst';
  static const _playerCutKey = 'playerCut';
  static const _opponentCutKey = 'opponentCut';
  static const _playerNameKey = 'playerName';
  static const _opponentNameKey = 'opponentName';

  @override
  StoredStats? loadStats() {
    return StoredStats(
      gamesWon: _prefs.getInt(_gamesWonKey) ?? 0,
      gamesLost: _prefs.getInt(_gamesLostKey) ?? 0,
      skunksFor: _prefs.getInt(_skunksForKey) ?? 0,
      skunksAgainst: _prefs.getInt(_skunksAgainstKey) ?? 0,
      doubleSkunksFor: _prefs.getInt(_doubleSkunksForKey) ?? 0,
      doubleSkunksAgainst: _prefs.getInt(_doubleSkunksAgainstKey) ?? 0,
    );
  }

  @override
  void saveStats({
    required int gamesWon,
    required int gamesLost,
    required int skunksFor,
    required int skunksAgainst,
    required int doubleSkunksFor,
    required int doubleSkunksAgainst,
  }) {
    try {
      _prefs
        ..setInt(_gamesWonKey, gamesWon)
        ..setInt(_gamesLostKey, gamesLost)
        ..setInt(_skunksForKey, skunksFor)
        ..setInt(_skunksAgainstKey, skunksAgainst)
        ..setInt(_doubleSkunksForKey, doubleSkunksFor)
        ..setInt(_doubleSkunksAgainstKey, doubleSkunksAgainst);

      if (kDebugMode) {
        debugPrint('[Persistence] Stats saved successfully: W:$gamesWon L:$gamesLost');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Persistence] ERROR saving stats: $e');
      }
      // Don't throw - gracefully degrade if persistence fails
    }
  }

  @override
  CutCards? loadCutCards() {
    try {
      final player = _prefs.getString(_playerCutKey);
      final opponent = _prefs.getString(_opponentCutKey);
      if (player == null || opponent == null) {
        if (kDebugMode) {
          debugPrint('[Persistence] No saved cut cards found');
        }
        return null;
      }

      final playerCard = PlayingCard.decode(player);
      final opponentCard = PlayingCard.decode(opponent);

      if (kDebugMode) {
        debugPrint('[Persistence] Cut cards loaded successfully: ${playerCard.label}, ${opponentCard.label}');
      }

      return CutCards(
        player: playerCard,
        opponent: opponentCard,
      );
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('[Persistence] ERROR: Invalid card format in saved data: $e');
      }
      // Return null if corrupted data - game will regenerate
      return null;
    } on RangeError catch (e) {
      if (kDebugMode) {
        debugPrint('[Persistence] ERROR: Card data out of range: $e');
      }
      // Return null if corrupted data - game will regenerate
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Persistence] ERROR loading cut cards: $e');
      }
      // Return null if corrupted data - game will regenerate
      return null;
    }
  }

  @override
  void saveCutCards(PlayingCard player, PlayingCard opponent) {
    try {
      _prefs
        ..setString(_playerCutKey, player.encode())
        ..setString(_opponentCutKey, opponent.encode());

      if (kDebugMode) {
        debugPrint('[Persistence] Cut cards saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Persistence] ERROR saving cut cards: $e');
      }
      // Don't throw - gracefully degrade if persistence fails
    }
  }

  @override
  PlayerNames? loadPlayerNames() {
    final playerName = _prefs.getString(_playerNameKey);
    final opponentName = _prefs.getString(_opponentNameKey);
    if (playerName == null || opponentName == null) {
      return null;
    }
    return PlayerNames(playerName: playerName, opponentName: opponentName);
  }

  @override
  void savePlayerNames({required String playerName, required String opponentName}) {
    try {
      _prefs
        ..setString(_playerNameKey, playerName)
        ..setString(_opponentNameKey, opponentName);

      if (kDebugMode) {
        debugPrint('[Persistence] Player names saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Persistence] ERROR saving player names: $e');
      }
      // Don't throw - gracefully degrade if persistence fails
    }
  }
}
