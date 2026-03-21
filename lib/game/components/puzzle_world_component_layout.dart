part of 'puzzle_world_component.dart';

/// Builds and positions slot/tile components and performs movement animation.
extension PuzzleWorldComponentLayout on PuzzleWorldComponent {
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
      final _TileConnection connection = _tileConnectionForIndex(boardIndex);
      final _TileRenderGeometry geometry = _tileRenderGeometry(
        boardIndex: boardIndex,
        connectTop: connection.top,
        connectRight: connection.right,
        connectBottom: connection.bottom,
        connectLeft: connection.left,
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
        showTopBorder: !connection.top,
        showRightBorder: !connection.right,
        showBottomBorder: !connection.bottom,
        showLeftBorder: !connection.left,
        roundTopLeft: !connection.top && !connection.left,
        roundTopRight: !connection.top && !connection.right,
        roundBottomRight: !connection.bottom && !connection.right,
        roundBottomLeft: !connection.bottom && !connection.left,
        showDragPlaceholder: isInDraggedCluster,
      );

      if (isInDraggedCluster) {
        tile.position = renderGeometry.position;
        continue;
      }

      _positionTile(
        tile: tile,
        target: renderGeometry.position,
        animate: animate,
      );
    }

    if (_dragGhost != null && _dragAnchorWorldPosition != null) {
      _dragGhost!.setAnchorWithDelta(
        anchor: _dragAnchorWorldPosition!,
        delta: _dragDelta,
      );
    }
  }

  void _recomputeTileSize() {
    if (_rows == 0 || _columns == 0) {
      _tileWidth = 0;
      _tileHeight = 0;
      return;
    }

    final Vector2 gameSize = findGame()?.size ?? Vector2.zero();
    final double availableWidth =
        gameSize.x - (PuzzleWorldComponent._boardInset * 2);
    final double availableHeight =
        gameSize.y - (PuzzleWorldComponent._boardInset * 2);

    final double baseTileWidth =
        (availableWidth - PuzzleWorldComponent._spacing * (_columns - 1)) /
        _columns;
    final double baseTileHeight =
        (availableHeight - PuzzleWorldComponent._spacing * (_rows - 1)) / _rows;

    _tileWidth = baseTileWidth * _boardScale;
    _tileHeight = baseTileHeight * _boardScale;

    if (!_tileWidth.isFinite || _tileWidth < 0) {
      _tileWidth = 0;
    }
    if (!_tileHeight.isFinite || _tileHeight < 0) {
      _tileHeight = 0;
    }

    final double boardWidth =
        _tileWidth * _columns + PuzzleWorldComponent._spacing * (_columns - 1);
    final double boardHeight =
        _tileHeight * _rows + PuzzleWorldComponent._spacing * (_rows - 1);

    _boardOriginX =
        PuzzleWorldComponent._boardInset + (availableWidth - boardWidth) / 2;
    _boardOriginY =
        PuzzleWorldComponent._boardInset + (availableHeight - boardHeight) / 2;

    if (!_boardOriginX.isFinite) {
      _boardOriginX = PuzzleWorldComponent._boardInset;
    }
    if (!_boardOriginY.isFinite) {
      _boardOriginY = PuzzleWorldComponent._boardInset;
    }
  }

  void _positionTile({
    required TileComponent tile,
    required Vector2 target,
    required bool animate,
  }) {
    if (!animate || tile.position.distanceTo(target) < 0.5) {
      tile.position = target;
      return;
    }

    _clearTileMoveEffects(tile);
    tile.add(
      MoveEffect.to(
        target,
        EffectController(duration: 0.36, curve: Curves.easeInOutCubic),
      ),
    );
  }

  void _clearTileMoveEffects(TileComponent tile) {
    final List<MoveEffect> existingEffects = tile.children
        .whereType<MoveEffect>()
        .toList();
    for (final MoveEffect effect in existingEffects) {
      effect.removeFromParent();
    }
  }
}
