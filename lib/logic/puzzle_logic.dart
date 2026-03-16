import 'dart:math';

import 'package:logging/logging.dart';

class PuzzleLogic {
  PuzzleLogic() : _random = Random();

  final Random _random;
  static final Logger _logger = Logger('PuzzleLogic');

  List<int> createShuffledTiles({required int rows, required int columns}) {
    final List<int> tiles = List<int>.generate(rows * columns, (i) => i);

    do {
      for (int i = tiles.length - 1; i > 0; i--) {
        final int j = _random.nextInt(i + 1);
        swapTiles(tiles, i, j);
      }
    } while (isSolved(tiles));

    return tiles;
  }

  bool isSolved(List<int> tiles) {
    _logger.fine('Checking if solved: $tiles');
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != i) {
        _logger.fine('Not solved!!');
        return false;
      }
    }
    return true;
  }

  void swapTiles(List<int> tiles, int a, int b) {
    final int temp = tiles[a];
    tiles[a] = tiles[b];
    tiles[b] = temp;
  }

  bool arePiecesCorrectNeighbors({
    required int pieceA,
    required int pieceB,
    required int boardDeltaRow,
    required int boardDeltaCol,
    required int columns,
  }) {
    final int solvedRowA = pieceA ~/ columns;
    final int solvedColA = pieceA % columns;
    final int solvedRowB = pieceB ~/ columns;
    final int solvedColB = pieceB % columns;

    return solvedRowB - solvedRowA == boardDeltaRow &&
        solvedColB - solvedColA == boardDeltaCol;
  }

  Map<int, Set<int>> buildConnectedClusters({
    required List<int> tiles,
    required int rows,
    required int columns,
  }) {
    final Map<int, Set<int>> adjacency = <int, Set<int>>{
      for (int i = 0; i < tiles.length; i++) i: <int>{},
    };

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final int index = row * columns + col;
        final int piece = tiles[index];

        if (col + 1 < columns) {
          final int rightIndex = index + 1;
          final int rightPiece = tiles[rightIndex];
          if (arePiecesCorrectNeighbors(
            pieceA: piece,
            pieceB: rightPiece,
            boardDeltaRow: 0,
            boardDeltaCol: 1,
            columns: columns,
          )) {
            adjacency[index]!.add(rightIndex);
            adjacency[rightIndex]!.add(index);
          }
        }

        if (row + 1 < rows) {
          final int belowIndex = index + columns;
          final int belowPiece = tiles[belowIndex];
          if (arePiecesCorrectNeighbors(
            pieceA: piece,
            pieceB: belowPiece,
            boardDeltaRow: 1,
            boardDeltaCol: 0,
            columns: columns,
          )) {
            adjacency[index]!.add(belowIndex);
            adjacency[belowIndex]!.add(index);
          }
        }
      }
    }

    final Set<int> visited = <int>{};
    final Map<int, Set<int>> clusters = <int, Set<int>>{};
    int clusterId = 0;

    for (int start = 0; start < tiles.length; start++) {
      if (visited.contains(start)) {
        continue;
      }

      final List<int> stack = <int>[start];
      final Set<int> members = <int>{};

      while (stack.isNotEmpty) {
        final int current = stack.removeLast();
        if (!visited.add(current)) {
          continue;
        }

        members.add(current);
        for (final int next in adjacency[current]!) {
          if (!visited.contains(next)) {
            stack.add(next);
          }
        }
      }

      clusters[clusterId] = members;
      clusterId++;
    }

    return clusters;
  }
}
