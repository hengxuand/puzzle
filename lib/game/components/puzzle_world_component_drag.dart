part of 'puzzle_world_component.dart';

extension PuzzleWorldComponentDrag on PuzzleWorldComponent {
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

    final _TileConnection anchorConnection = _tileConnectionForIndex(
      tile.boardIndex,
    );
    final _TileRenderGeometry anchorGeometry = _tileRenderGeometry(
      boardIndex: tile.boardIndex,
      connectTop: anchorConnection.top,
      connectRight: anchorConnection.right,
      connectBottom: anchorConnection.bottom,
      connectLeft: anchorConnection.left,
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

      final _TileConnection connection = _tileConnectionForIndex(
        memberBoardIndex,
      );
      final _TileRenderGeometry geometry = _tileRenderGeometry(
        boardIndex: memberBoardIndex,
        connectTop: connection.top,
        connectRight: connection.right,
        connectBottom: connection.bottom,
        connectLeft: connection.left,
      );

      ghostPieces.add(
        GhostPieceData(
          sprite: _spriteForPiece(pieceIndex),
          relativeOffset: geometry.position - anchorGeometry.position,
          size: geometry.size,
          roundTopLeft: !connection.top && !connection.left,
          roundTopRight: !connection.top && !connection.right,
          roundBottomRight: !connection.bottom && !connection.right,
          roundBottomLeft: !connection.bottom && !connection.left,
        ),
      );

      component.applyVisualState(
        isInActiveCluster: true,
        isDragging: false,
        showTopBorder: !connection.top,
        showRightBorder: !connection.right,
        showBottomBorder: !connection.bottom,
        showLeftBorder: !connection.left,
        roundTopLeft: !connection.top && !connection.left,
        roundTopRight: !connection.top && !connection.right,
        roundBottomRight: !connection.bottom && !connection.right,
        roundBottomLeft: !connection.bottom && !connection.left,
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
    final double xStep = _tileWidth + PuzzleWorldComponent._spacing;
    final double yStep = _tileHeight + PuzzleWorldComponent._spacing;

    if (xStep <= 0 || yStep <= 0) {
      return null;
    }

    final double fractionalRow = (projected.y - _boardOriginY) / yStep;
    final double fractionalCol = (projected.x - _boardOriginX) / xStep;

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
    if ((value - rounded).abs() < PuzzleWorldComponent._dragSnapThreshold) {
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
}
