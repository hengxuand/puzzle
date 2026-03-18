import 'dart:ui' as ui;

import 'package:discovery_puzzle/game/components/board_slot_component.dart';
import 'package:discovery_puzzle/game/components/cluster_drag_ghost_component.dart';
import 'package:discovery_puzzle/game/components/tile_component.dart';
import 'package:discovery_puzzle/state/game/puzzle_game_controller.dart';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class PuzzleWorldComponent extends Component {
  PuzzleWorldComponent({required this.controller});

  final PuzzleGameController controller;

  static const double _spacing = 1.5;
  static const double _boardInset = 3.0;
  static const double _dragSnapThreshold = 0.45;
  static const double _connectedSeamEpsilon = 0.35;

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

  int? _dragAnchorIndex;
  int? _dragClusterId;
  Vector2 _dragDelta = Vector2.zero();
  Vector2? _dragAnchorWorldPosition;
  ClusterDragGhostComponent? _dragGhost;

  void syncFromController({required ui.Image image}) {
    final int nextRows = controller.rowCount;
    final int nextColumns = controller.columnCount;
    final List<int> nextTiles = controller.tiles.toList(growable: false);

    final bool structureChanged =
        _rows != nextRows ||
        _columns != nextColumns ||
        _tiles.length != nextTiles.length;
    final bool imageChanged = !identical(image, _image);

    _rows = nextRows;
    _columns = nextColumns;
    _tiles = nextTiles;
    _image = image;

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

  void _rebuildTiles() {
    _dragGhost?.removeFromParent();
    _dragGhost = null;

    for (final BoardSlotComponent slot in _slotsByIndex.values) {
      slot.removeFromParent();
    }
    _slotsByIndex.clear();

    for (final TileComponent tile in _tilesByPiece.values) {
      tile.removeFromParent();
    }
    _tilesByPiece.clear();

    if (_image == null || _rows == 0 || _columns == 0) {
      return;
    }

    final Vector2 tileSize = Vector2(_tileWidth, _tileHeight);

    for (int boardIndex = 0; boardIndex < _tiles.length; boardIndex++) {
      final BoardSlotComponent slot = BoardSlotComponent(boardIndex: boardIndex)
        ..position = _positionForBoardIndex(boardIndex)
        ..size = tileSize;

      _slotsByIndex[boardIndex] = slot;
      add(slot);
    }

    for (int boardIndex = 0; boardIndex < _tiles.length; boardIndex++) {
      final int pieceIndex = _tiles[boardIndex];

      final TileComponent tile =
          TileComponent(
              pieceIndex: pieceIndex,
              boardIndex: boardIndex,
              onDragStartRequested: _handleTileDragStart,
              onDragDeltaRequested: _handleTileDragUpdate,
              onDragEndRequested: _handleTileDragEnd,
            )
            ..position = _positionForBoardIndex(boardIndex)
            ..syncFrame(
              sprite: _spriteForPiece(pieceIndex),
              newBoardIndex: boardIndex,
              tileSize: tileSize,
            );

      _tilesByPiece[pieceIndex] = tile;
      add(tile);
    }
  }

  void _layoutTiles({required bool animate}) {
    if (_rows == 0 || _columns == 0) {
      return;
    }

    final Vector2 tileSize = Vector2(_tileWidth, _tileHeight);

    for (int boardIndex = 0; boardIndex < _tiles.length; boardIndex++) {
      final BoardSlotComponent? slot = _slotsByIndex[boardIndex];
      if (slot == null) {
        continue;
      }

      slot
        ..position = _positionForBoardIndex(boardIndex)
        ..size = tileSize
        ..setHovered(controller.hoveredTargetIndex.value == boardIndex);
    }

    for (int boardIndex = 0; boardIndex < _tiles.length; boardIndex++) {
      final int pieceIndex = _tiles[boardIndex];
      final TileComponent? tile = _tilesByPiece[pieceIndex];
      if (tile == null) {
        continue;
      }
      final bool isInDraggedCluster = _dragMemberIndices.contains(boardIndex);
      final bool topConnected = _isDirectlyConnectedNeighbor(
        boardIndex: boardIndex,
        deltaRow: -1,
        deltaCol: 0,
      );
      final bool rightConnected = _isDirectlyConnectedNeighbor(
        boardIndex: boardIndex,
        deltaRow: 0,
        deltaCol: 1,
      );
      final bool bottomConnected = _isDirectlyConnectedNeighbor(
        boardIndex: boardIndex,
        deltaRow: 1,
        deltaCol: 0,
      );
      final bool leftConnected = _isDirectlyConnectedNeighbor(
        boardIndex: boardIndex,
        deltaRow: 0,
        deltaCol: -1,
      );
      final _TileRenderGeometry geometry = _tileRenderGeometry(
        boardIndex: boardIndex,
        connectTop: topConnected,
        connectRight: rightConnected,
        connectBottom: bottomConnected,
        connectLeft: leftConnected,
      );
      final _TileRenderGeometry baseGeometry = _TileRenderGeometry(
        position: _positionForBoardIndex(boardIndex),
        size: tileSize,
      );
      final _TileRenderGeometry renderGeometry = isInDraggedCluster
          ? baseGeometry
          : geometry;

      tile.syncFrame(
        sprite: _spriteForPiece(pieceIndex),
        newBoardIndex: boardIndex,
        tileSize: renderGeometry.size,
      );

      tile.applyVisualState(
        isInActiveCluster: controller.isBoardIndexInActiveDragCluster(
          boardIndex,
        ),
        isDragging: false,
        showTopBorder: !topConnected,
        showRightBorder: !rightConnected,
        showBottomBorder: !bottomConnected,
        showLeftBorder: !leftConnected,
        roundTopLeft: !topConnected && !leftConnected,
        roundTopRight: !topConnected && !rightConnected,
        roundBottomRight: !bottomConnected && !rightConnected,
        roundBottomLeft: !bottomConnected && !leftConnected,
        showDragPlaceholder: isInDraggedCluster,
      );

      if (isInDraggedCluster) {
        tile.position = renderGeometry.position;
        continue;
      }

      final Vector2 target = renderGeometry.position;
      if (!animate) {
        tile.position = target;
        continue;
      }

      if (tile.position.distanceTo(target) < 0.5) {
        tile.position = target;
        continue;
      }

      final List<MoveEffect> existingEffects = tile.children
          .whereType<MoveEffect>()
          .toList();
      for (final MoveEffect effect in existingEffects) {
        effect.removeFromParent();
      }

      tile.add(
        MoveEffect.to(
          target,
          EffectController(duration: 0.36, curve: Curves.easeInOutCubic),
        ),
      );
    }

    if (_dragGhost != null && _dragAnchorWorldPosition != null) {
      _dragGhost!.setAnchorWithDelta(
        anchor: _dragAnchorWorldPosition!,
        delta: _dragDelta,
      );
    }
  }

  void _handleTileDragStart(TileComponent tile) {
    if (_tiles.isEmpty) {
      return;
    }

    controller.startDrag(tile.boardIndex);

    _dragAnchorIndex = tile.boardIndex;
    _dragClusterId = controller.activeDragClusterId.value;
    _dragDelta = Vector2.zero();

    final List<int> members = _dragClusterId == null
        ? <int>[tile.boardIndex]
        : controller.clusterMembersForId(_dragClusterId!);

    _dragMemberIndices = members.toSet();

    final bool anchorTopConnected = _isDirectlyConnectedNeighbor(
      boardIndex: tile.boardIndex,
      deltaRow: -1,
      deltaCol: 0,
    );
    final bool anchorRightConnected = _isDirectlyConnectedNeighbor(
      boardIndex: tile.boardIndex,
      deltaRow: 0,
      deltaCol: 1,
    );
    final bool anchorBottomConnected = _isDirectlyConnectedNeighbor(
      boardIndex: tile.boardIndex,
      deltaRow: 1,
      deltaCol: 0,
    );
    final bool anchorLeftConnected = _isDirectlyConnectedNeighbor(
      boardIndex: tile.boardIndex,
      deltaRow: 0,
      deltaCol: -1,
    );
    final _TileRenderGeometry anchorGeometry = _tileRenderGeometry(
      boardIndex: tile.boardIndex,
      connectTop: anchorTopConnected,
      connectRight: anchorRightConnected,
      connectBottom: anchorBottomConnected,
      connectLeft: anchorLeftConnected,
    );
    _dragAnchorWorldPosition = anchorGeometry.position.clone();

    final List<GhostPieceData> ghostPieces = <GhostPieceData>[];

    for (final int memberBoardIndex in _dragMemberIndices) {
      if (memberBoardIndex < 0 || memberBoardIndex >= _tiles.length) {
        continue;
      }

      final int pieceIndex = _tiles[memberBoardIndex];
      final TileComponent? component = _tilesByPiece[pieceIndex];
      if (component == null) {
        continue;
      }

      final bool topConnected = _isDirectlyConnectedNeighbor(
        boardIndex: memberBoardIndex,
        deltaRow: -1,
        deltaCol: 0,
      );
      final bool rightConnected = _isDirectlyConnectedNeighbor(
        boardIndex: memberBoardIndex,
        deltaRow: 0,
        deltaCol: 1,
      );
      final bool bottomConnected = _isDirectlyConnectedNeighbor(
        boardIndex: memberBoardIndex,
        deltaRow: 1,
        deltaCol: 0,
      );
      final bool leftConnected = _isDirectlyConnectedNeighbor(
        boardIndex: memberBoardIndex,
        deltaRow: 0,
        deltaCol: -1,
      );
      final _TileRenderGeometry geometry = _tileRenderGeometry(
        boardIndex: memberBoardIndex,
        connectTop: topConnected,
        connectRight: rightConnected,
        connectBottom: bottomConnected,
        connectLeft: leftConnected,
      );

      ghostPieces.add(
        GhostPieceData(
          sprite: _spriteForPiece(pieceIndex),
          relativeOffset: geometry.position - anchorGeometry.position,
          size: geometry.size,
          roundTopLeft: !topConnected && !leftConnected,
          roundTopRight: !topConnected && !rightConnected,
          roundBottomRight: !bottomConnected && !rightConnected,
          roundBottomLeft: !bottomConnected && !leftConnected,
        ),
      );

      component.applyVisualState(
        isInActiveCluster: true,
        isDragging: false,
        showTopBorder: !topConnected,
        showRightBorder: !rightConnected,
        showBottomBorder: !bottomConnected,
        showLeftBorder: !leftConnected,
        roundTopLeft: !topConnected && !leftConnected,
        roundTopRight: !topConnected && !rightConnected,
        roundBottomRight: !bottomConnected && !rightConnected,
        roundBottomLeft: !bottomConnected && !leftConnected,
        showDragPlaceholder: true,
      );
    }

    final ClusterDragGhostComponent ghost = _dragGhost ??=
        ClusterDragGhostComponent();
    if (ghost.parent == null) {
      add(ghost);
    }
    ghost.setFromData(
      anchorPosition: _dragAnchorWorldPosition ?? Vector2.zero(),
      pieces: ghostPieces,
    );
  }

  bool _isDirectlyConnectedNeighbor({
    required int boardIndex,
    required int deltaRow,
    required int deltaCol,
  }) {
    if (boardIndex < 0 || boardIndex >= _tiles.length) {
      return false;
    }

    final int row = boardIndex ~/ _columns;
    final int col = boardIndex % _columns;
    final int neighborRow = row + deltaRow;
    final int neighborCol = col + deltaCol;

    if (neighborRow < 0 ||
        neighborRow >= _rows ||
        neighborCol < 0 ||
        neighborCol >= _columns) {
      return false;
    }

    final int neighborIndex = neighborRow * _columns + neighborCol;
    final int pieceA = _tiles[boardIndex];
    final int pieceB = _tiles[neighborIndex];

    final int solvedRowA = pieceA ~/ _columns;
    final int solvedColA = pieceA % _columns;
    final int solvedRowB = pieceB ~/ _columns;
    final int solvedColB = pieceB % _columns;

    return solvedRowB - solvedRowA == deltaRow &&
        solvedColB - solvedColA == deltaCol;
  }

  _TileRenderGeometry _tileRenderGeometry({
    required int boardIndex,
    required bool connectTop,
    required bool connectRight,
    required bool connectBottom,
    required bool connectLeft,
  }) {
    final Vector2 position = _positionForBoardIndex(boardIndex).clone();
    final Vector2 size = Vector2(_tileWidth, _tileHeight);
    final double overlap = _spacing / 2 + _connectedSeamEpsilon;

    if (connectLeft) {
      position.x -= overlap;
      size.x += overlap;
    }
    if (connectRight) {
      size.x += overlap;
    }
    if (connectTop) {
      position.y -= overlap;
      size.y += overlap;
    }
    if (connectBottom) {
      size.y += overlap;
    }

    return _TileRenderGeometry(position: position, size: size);
  }

  void _handleTileDragUpdate(Vector2 delta) {
    if (_dragMemberIndices.isEmpty) {
      return;
    }

    _dragDelta += delta;

    final int? projectedTarget = _projectDropTarget();
    controller.setHoveredTarget(projectedTarget);
    _layoutTiles(animate: false);
  }

  void _handleTileDragEnd() {
    final int? clusterId = _dragClusterId;
    final int? fromAnchorIndex = _dragAnchorIndex;
    final int? toAnchorIndex = _projectDropTarget();

    if (clusterId != null &&
        fromAnchorIndex != null &&
        toAnchorIndex != null &&
        controller.canAcceptClusterDrop(
          clusterId: clusterId,
          fromAnchorIndex: fromAnchorIndex,
          toAnchorIndex: toAnchorIndex,
        )) {
      controller.moveClusterFromDrag(
        clusterId: clusterId,
        fromAnchorIndex: fromAnchorIndex,
        toAnchorIndex: toAnchorIndex,
      );
    } else {
      controller.endDrag();
    }

    _clearDragState();
    _layoutTiles(animate: false);
  }

  int? _projectDropTarget() {
    final int? fromAnchorIndex = _dragAnchorIndex;
    final int? clusterId = _dragClusterId;
    if (fromAnchorIndex == null || clusterId == null) {
      return null;
    }

    final Vector2 projected =
        _positionForBoardIndex(fromAnchorIndex) + _dragDelta;
    final double xStep = _tileWidth + _spacing;
    final double yStep = _tileHeight + _spacing;

    if (xStep <= 0 || yStep <= 0) {
      return null;
    }

    final double fractionalCol = (projected.x - _boardInset) / xStep;
    final double fractionalRow = (projected.y - _boardInset) / yStep;

    final int targetCol = _snapIndex(fractionalCol);
    final int targetRow = _snapIndex(fractionalRow);

    if (targetCol < 0 ||
        targetCol >= _columns ||
        targetRow < 0 ||
        targetRow >= _rows) {
      return null;
    }

    final int targetIndex = targetRow * _columns + targetCol;

    final bool canAccept = controller.canAcceptClusterDrop(
      clusterId: clusterId,
      fromAnchorIndex: fromAnchorIndex,
      toAnchorIndex: targetIndex,
    );

    return canAccept ? targetIndex : null;
  }

  int _snapIndex(double value) {
    final double rounded = value.roundToDouble();
    if ((value - rounded).abs() < _dragSnapThreshold) {
      return rounded.toInt();
    }
    return value.floor();
  }

  void _clearDragState() {
    _dragGhost?.removeFromParent();
    _dragGhost = null;
    _dragAnchorIndex = null;
    _dragClusterId = null;
    _dragDelta = Vector2.zero();
    _dragAnchorWorldPosition = null;
    _dragMemberIndices = <int>{};
  }

  Sprite _spriteForPiece(int pieceIndex) {
    final ui.Image image = _image!;

    final int row = pieceIndex ~/ _columns;
    final int col = pieceIndex % _columns;

    final double sourceTileWidth = image.width / _columns;
    final double sourceTileHeight = image.height / _rows;

    return Sprite(
      image,
      srcPosition: Vector2(col * sourceTileWidth, row * sourceTileHeight),
      srcSize: Vector2(sourceTileWidth, sourceTileHeight),
    );
  }

  Vector2 _positionForBoardIndex(int boardIndex) {
    final int row = boardIndex ~/ _columns;
    final int col = boardIndex % _columns;
    return Vector2(
      _boardInset + col * (_tileWidth + _spacing),
      _boardInset + row * (_tileHeight + _spacing),
    );
  }

  void _recomputeTileSize() {
    if (_rows == 0 || _columns == 0) {
      _tileWidth = 0;
      _tileHeight = 0;
      return;
    }

    final Vector2 gameSize = findGame()?.size ?? Vector2.zero();
    final double availableWidth = gameSize.x - (_boardInset * 2);
    final double availableHeight = gameSize.y - (_boardInset * 2);

    _tileWidth = (availableWidth - _spacing * (_columns - 1)) / _columns;
    _tileHeight = (availableHeight - _spacing * (_rows - 1)) / _rows;

    if (!_tileWidth.isFinite || _tileWidth < 0) {
      _tileWidth = 0;
    }
    if (!_tileHeight.isFinite || _tileHeight < 0) {
      _tileHeight = 0;
    }
  }
}

class _TileRenderGeometry {
  const _TileRenderGeometry({required this.position, required this.size});

  final Vector2 position;
  final Vector2 size;
}
