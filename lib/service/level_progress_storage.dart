import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressSnapshot {
  const LevelProgressSnapshot({
    required this.selectedLevelId,
    required this.unlockedLevelIds,
    required this.completedLevelIds,
  });

  final String? selectedLevelId;
  final List<String> unlockedLevelIds;
  final List<String> completedLevelIds;
}

class LevelProgressStorage {
  static const String _selectedLevelKey = 'selected_level_id';
  static const String _unlockedLevelsKey = 'unlocked_level_ids';
  static const String _completedLevelsKey = 'completed_level_ids';

  const LevelProgressStorage();

  Future<LevelProgressSnapshot> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return LevelProgressSnapshot(
      selectedLevelId: prefs.getString(_selectedLevelKey),
      unlockedLevelIds:
          prefs.getStringList(_unlockedLevelsKey) ?? const <String>[],
      completedLevelIds:
          prefs.getStringList(_completedLevelsKey) ?? const <String>[],
    );
  }

  Future<void> saveSelectedLevel(String levelId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLevelKey, levelId);
  }

  Future<void> saveUnlockedLevelIds(List<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedLevelsKey, ids);
  }

  Future<void> saveCompletedLevelIds(List<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedLevelsKey, ids);
  }
}
