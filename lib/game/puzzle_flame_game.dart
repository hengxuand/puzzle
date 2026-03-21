import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:puzzle/config/app_config.dart';
import 'package:puzzle/game/components/puzzle_world_component.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class PuzzleFlameGame extends FlameGame {
  PuzzleFlameGame({required this.controller});

  final PuzzleGameController controller;

  PuzzleWorldComponent? _world;
  String _lastStateKey = '';
  ui.Image? _lastImage;

  @override
  ui.Color backgroundColor() => AppConfig.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _syncBoard(force: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncBoard();
  }

  void _syncBoard({bool force = false}) {
    final ui.Image? image = controller.imageAsync.value;
    if (image == null) {
      return;
    }

    final String stateKey =
        '${controller.selectedLevel.value?.id ?? 'none'}:${controller.rowCount}x${controller.columnCount}:${controller.tiles.join(',')}:${controller.activeDragClusterId.value ?? -1}:${controller.hoveredTargetIndex.value ?? -1}';

    if (!force && stateKey == _lastStateKey && identical(image, _lastImage)) {
      return;
    }

    _lastStateKey = stateKey;
    _lastImage = image;

    final PuzzleWorldComponent world = _world ??= PuzzleWorldComponent(
      controller: controller,
    );
    if (world.parent == null) {
      add(world);
    }

    world.syncFromController(image: image);
  }
}
