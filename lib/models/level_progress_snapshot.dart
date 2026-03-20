import 'package:puzzle/models/level_group.dart';

class LevelProgressSnapshot {
  const LevelProgressSnapshot({required this.groups});

  final Map<int, LevelGroup> groups;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': 1,
      'groups': groups.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
    };
  }

  static LevelProgressSnapshot? fromJson(Map<String, dynamic> decoded) {
    if (decoded.isEmpty) {
      return null;
    }

    final dynamic rawGroups = decoded['groups'];

    final Map<int, LevelGroup> groups;
    if (rawGroups is Map<String, dynamic>) {
      groups = Map<int, LevelGroup>.fromEntries(
        rawGroups.entries
            .where((entry) => entry.value is Map<String, dynamic>)
            .map(
              (entry) => MapEntry(
                _parseGroupId(entry.key),
                LevelGroup.fromJson(<String, dynamic>{
                  ...((entry.value as Map<String, dynamic>)),
                  'id':
                      (entry.value as Map<String, dynamic>)['id'] ?? entry.key,
                }),
              ),
            ),
      );
    } else {
      final List<dynamic> groupsJson =
          (rawGroups as List<dynamic>?) ?? const <dynamic>[];
      groups = Map<int, LevelGroup>.fromEntries(
        groupsJson
            .whereType<Map<String, dynamic>>()
            .map(LevelGroup.fromJson)
            .map((group) => MapEntry(group.id, group)),
      );
    }

    return LevelProgressSnapshot(groups: groups);
  }

  static int _parseGroupId(String rawGroupId) {
    final int? direct = int.tryParse(rawGroupId);
    if (direct != null) {
      return direct;
    }

    throw FormatException('Invalid group id: $rawGroupId');
  }
}
