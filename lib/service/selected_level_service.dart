import 'dart:async';
import 'dart:convert';

import 'package:discovery_puzzle/models/game_level.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedLevelService extends GetxService {
  late SharedPreferences _prefs;

  static const String _selectedLevelKey = 'selected_level';

  Future<SelectedLevelService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  Future<void> saveSelectedLevel(GameLevel level) async {
    final jsonString = jsonEncode(level.toJson());

    await _prefs.setString(_selectedLevelKey, jsonString);
  }

  GameLevel? loadSelectedLevel() {
    final jsonString = _prefs.getString(_selectedLevelKey);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    final Map<String, dynamic> decoded = jsonDecode(jsonString);

    return GameLevel.fromJson(decoded);
  }

  Future<void> clearSelectedLevel() async {
    await _prefs.remove(_selectedLevelKey);
  }
}
