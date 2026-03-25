import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:get/get.dart';
import 'package:puzzle/config/app_config.dart';
import 'package:puzzle/game/components/puzzle_world_component.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class PuzzleFlameGame extends FlameGame {
  PuzzleFlameGame({required this.controller});

  final PuzzleGameController controller;

  PuzzleWorldComponent? _world;
  Worker? _stateWorker;
  bool _stateDirty = true;

  @override
  ui.Color backgroundColor() => AppConfig.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _stateWorker ??= everAll(<RxInterface<dynamic>>[
      controller.imageAsync,
      controller.selectedLevel,
      controller.tiles,
      controller.activeDragClusterId,
      controller.hoveredTargetIndex,
    ], (_) => _stateDirty = true);
    _syncBoard(force: true);
    _stateDirty = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_stateDirty) {
      _syncBoard();
      _stateDirty = false;
    }
  }

  @override
  void onRemove() {
    _stateWorker?.dispose();
    _stateWorker = null;
    super.onRemove();
  }

  void _syncBoard({bool force = false}) {
    final ui.Image? image = controller.imageAsync.value;
    if (image == null) {
      return;
    }

    final PuzzleWorldComponent world = _world ??= PuzzleWorldComponent(
      controller: controller,
    );
    if (world.parent == null) {
      add(world);
    }

    world.syncFromController(image: image);
  }
}
