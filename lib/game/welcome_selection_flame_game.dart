import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:get/get.dart';
import 'package:puzzle/config/app_config.dart';
import 'package:puzzle/game/components/welcome_selector_world_component.dart';
import 'package:puzzle/models/level_group.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class WelcomeSelectionFlameGame extends FlameGame {
  WelcomeSelectionFlameGame({required this.controller});

  final PuzzleGameController controller;

  WelcomeSelectorWorldComponent? _world;
  Worker? _stateWorker;
  bool _stateDirty = true;

  @override
  ui.Color backgroundColor() => AppConfig.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _stateWorker ??= everAll(<RxInterface<dynamic>>[
      controller.progressSnapshot,
      controller.selectedGroupId,
      controller.selectedLevel,
    ], (_) => _stateDirty = true);
    _syncState(force: true);
    _stateDirty = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_stateDirty) {
      _syncState();
      _stateDirty = false;
    }
  }

  @override
  void onRemove() {
    _stateWorker?.dispose();
    _stateWorker = null;
    super.onRemove();
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
}
