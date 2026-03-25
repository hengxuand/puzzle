part of 'puzzle_world_component.dart';

extension PuzzleWorldComponentGeometry on PuzzleWorldComponent {
  _TileConnection _tileConnectionForIndex(int boardIndex) {
    return _TileConnection(
      top: _isDirectlyConnectedNeighbor(
        boardIndex: boardIndex,
        deltaRow: -1,
        deltaCol: 0,
      ),
      right: _isDirectlyConnectedNeighbor(
        boardIndex: boardIndex,
        deltaRow: 0,
        deltaCol: 1,
      ),
      bottom: _isDirectlyConnectedNeighbor(
        boardIndex: boardIndex,
        deltaRow: 1,
        deltaCol: 0,
      ),
      left: _isDirectlyConnectedNeighbor(
        boardIndex: boardIndex,
        deltaRow: 0,
        deltaCol: -1,
      ),
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
    final int row = boardIndex ~/ _columns;
    final int col = boardIndex % _columns;
    final double step = PuzzleWorldComponent._spacing;
    double px = _boardOriginX + col * (_tileWidth + step);
    double py = _boardOriginY + row * (_tileHeight + step);
    double sx = _tileWidth;
    double sy = _tileHeight;
    final double overlap =
        step / 2 + PuzzleWorldComponent._connectedSeamEpsilon;

    if (connectLeft) {
      px -= overlap;
      sx += overlap;
    }
    if (connectRight) {
      sx += overlap;
    }
    if (connectTop) {
      py -= overlap;
      sy += overlap;
    }
    if (connectBottom) {
      sy += overlap;
    }

    return _TileRenderGeometry(
      position: Vector2(px, py),
      size: Vector2(sx, sy),
    );
  }

  Sprite _spriteForPiece(int pieceIndex) {
    final Sprite? cached = _spriteCache[pieceIndex];
    if (cached != null) {
      return cached;
    }

    final ui.Image image = _image!;

    final int row = pieceIndex ~/ _columns;
    final int col = pieceIndex % _columns;

    final double sourceTileWidth = image.width / _columns;
    final double sourceTileHeight = image.height / _rows;

    final Sprite sprite = Sprite(
      image,
      srcPosition: Vector2(col * sourceTileWidth, row * sourceTileHeight),
      srcSize: Vector2(sourceTileWidth, sourceTileHeight),
    );
    _spriteCache[pieceIndex] = sprite;
    return sprite;
  }

  Vector2 _positionForBoardIndex(int boardIndex) {
    final int row = boardIndex ~/ _columns;
    final int col = boardIndex % _columns;
    return Vector2(
      _boardOriginX + col * (_tileWidth + PuzzleWorldComponent._spacing),
      _boardOriginY + row * (_tileHeight + PuzzleWorldComponent._spacing),
    );
  }
}

class _TileRenderGeometry {
  const _TileRenderGeometry({required this.position, required this.size});

  final Vector2 position;
  final Vector2 size;
}

class _TileConnection {
  const _TileConnection({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final bool top;
  final bool right;
  final bool bottom;
  final bool left;
}
