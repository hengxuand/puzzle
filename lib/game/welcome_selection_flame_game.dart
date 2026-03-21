import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:puzzle/config/app_config.dart';
import 'package:puzzle/game/components/welcome_selector_world_component.dart';
import 'package:puzzle/models/level_group.dart';
import 'package:puzzle/models/level_progress_status.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class WelcomeSelectionFlameGame extends FlameGame {
  WelcomeSelectionFlameGame({required this.controller});

  final PuzzleGameController controller;

  WelcomeSelectorWorldComponent? _world;
  String _lastStateKey = '';

  @override
  ui.Color backgroundColor() => AppConfig.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _syncState(force: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncState();
  }

  void _syncState({bool force = false}) {
    final List<LevelGroup> groups =
        (controller.progressSnapshot.value?.groups.values.toList(
                growable: false,
              ) ??
              <LevelGroup>[])
          ..sort((a, b) {
            final int byOrder = a.order.compareTo(b.order);
            if (byOrder != 0) {
              return byOrder;
            }
            return a.id.compareTo(b.id);
          });

    final String stateKey = _buildStateKey(groups);
    if (!force && stateKey == _lastStateKey) {
      return;
    }
    _lastStateKey = stateKey;

    final WelcomeSelectorWorldComponent world = _world ??=
        WelcomeSelectorWorldComponent(
          onGroupChanged: controller.selectGroup,
          onLevelTapped: controller.selectLevel,
          isLocked: controller.isLocked,
          isCompleted: controller.isCompleted,
        );

    if (world.parent == null) {
      add(world);
    }

    world.syncFromController(
      groups: groups,
      selectedGroupId: controller.selectedGroupId.value,
      selectedLevelId: controller.selectedLevel.value?.id,
    );
  }

  String _buildStateKey(List<LevelGroup> groups) {
    final String groupsKey = groups
        .map((group) {
          final levels = group.levels.values.toList(growable: false)
            ..sort((a, b) => a.id.compareTo(b.id));
          final String levelsKey = levels
              .map((level) => '${level.id}:${level.status.wireValue}')
              .join(',');
          return '${group.id}[$levelsKey]';
        })
        .join('|');

    return '${controller.selectedGroupId.value ?? -1}:${controller.selectedLevel.value?.id ?? -1}:$groupsKey';
  }
}
