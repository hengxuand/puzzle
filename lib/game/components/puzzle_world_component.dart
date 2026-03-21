import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:puzzle/game/components/board_slot_component.dart';
import 'package:puzzle/game/components/cluster_drag_ghost_component.dart';
import 'package:puzzle/game/components/tile_component.dart';
import 'package:puzzle/models/level_progress_status.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

part 'puzzle_world_component_drag.dart';
part 'puzzle_world_component_geometry.dart';
part 'puzzle_world_component_layout.dart';

/// Flame-side view adapter that renders the board and forwards drag interactions
/// to [PuzzleGameController].
class PuzzleWorldComponent extends Component {
  PuzzleWorldComponent({required this.controller});

  final PuzzleGameController controller;

  static const double _spacing = 1.5;
  static const double _boardInset = 3.0;
  static const double _dragSnapThreshold = 0.45;
  static const double _connectedSeamEpsilon = 0.35;
  static const double _solvedBoardScale = 0.78;
  static const double _boardScaleSmoothing = 2.2;

  final Map<int, BoardSlotComponent> _slotsByIndex =
      <int, BoardSlotComponent>{};
  final Map<int, TileComponent> _tilesByPiece = <int, TileComponent>{};

  List<int> _tiles = const <int>[];
  Set<int> _dragMemberIndices = <int>{};
  int _rows = 0;
  int _columns = 0;

  ui.Image? _image;

  double _tileWidth = 0;
  double _tileHeight = 0;
  double _boardOriginX = _boardInset;
  double _boardOriginY = _boardInset;
  double _boardScale = 1.0;
  double _targetBoardScale = 1.0;

  int? _dragAnchorIndex;
  int? _dragClusterId;
  Vector2 _dragDelta = Vector2.zero();
  Vector2? _dragAnchorWorldPosition;
  ClusterDragGhostComponent? _dragGhost;

  @override
  void update(double dt) {
    super.update(dt);

    if ((_boardScale - _targetBoardScale).abs() < 0.001) {
      return;
    }

    final double t = 1 - math.exp(-_boardScaleSmoothing * dt);
    _boardScale += (_targetBoardScale - _boardScale) * t;
    _recomputeTileSize();
    _layoutTiles(animate: false);
  }

  void syncFromController({required ui.Image image}) {
    final int nextRows = controller.rowCount;
    final int nextColumns = controller.columnCount;
    final List<int> nextTiles = controller.tiles.toList(growable: false);
    final bool isSolved =
        controller.selectedLevel.value?.status == LevelProgressStatus.completed;

    final bool structureChanged =
        _rows != nextRows ||
        _columns != nextColumns ||
        _tiles.length != nextTiles.length;
    final bool imageChanged = !identical(image, _image);

    _rows = nextRows;
    _columns = nextColumns;
    _tiles = nextTiles;
    _image = image;
    _targetBoardScale = isSolved ? _solvedBoardScale : 1.0;

    _recomputeTileSize();

    if (structureChanged || imageChanged) {
      _rebuildTiles();
      _layoutTiles(animate: false);
      return;
    }

    _layoutTiles(animate: true);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recomputeTileSize();
    _layoutTiles(animate: false);
  }
}
