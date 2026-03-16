import 'package:discovery_puzzle/logic/puzzle_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleLogic', () {
    test('createShuffledTiles returns complete unsolved permutation', () {
      final PuzzleLogic logic = PuzzleLogic();

      final List<int> tiles = logic.createShuffledTiles(rows: 3, columns: 3);

      expect(tiles.length, 9);
      expect(tiles.toSet().length, 9);
      expect(tiles.toSet(), Set<int>.from(List<int>.generate(9, (i) => i)));
      expect(logic.isSolved(tiles), isFalse);
    });

    test('swapTiles swaps in place', () {
      final PuzzleLogic logic = PuzzleLogic();
      final List<int> tiles = <int>[0, 1, 2, 3];

      logic.swapTiles(tiles, 1, 3);

      expect(tiles, <int>[0, 3, 2, 1]);
    });

    test('arePiecesCorrectNeighbors validates solved-relative deltas', () {
      final PuzzleLogic logic = PuzzleLogic();

      expect(
        logic.arePiecesCorrectNeighbors(
          pieceA: 0,
          pieceB: 1,
          boardDeltaRow: 0,
          boardDeltaCol: 1,
          columns: 2,
        ),
        isTrue,
      );

      expect(
        logic.arePiecesCorrectNeighbors(
          pieceA: 0,
          pieceB: 2,
          boardDeltaRow: 1,
          boardDeltaCol: 0,
          columns: 2,
        ),
        isTrue,
      );

      expect(
        logic.arePiecesCorrectNeighbors(
          pieceA: 0,
          pieceB: 3,
          boardDeltaRow: 1,
          boardDeltaCol: 0,
          columns: 2,
        ),
        isFalse,
      );
    });

    test('buildConnectedClusters finds expected groups', () {
      final PuzzleLogic logic = PuzzleLogic();

      final Map<int, Set<int>> clusters = logic.buildConnectedClusters(
        tiles: <int>[0, 1, 3, 2],
        rows: 2,
        columns: 2,
      );

      final List<Set<int>> members = clusters.values.toList();
      expect(members.length, 3);
      expect(members.any((set) => setEquals(set, <int>{0, 1})), isTrue);
      expect(members.any((set) => setEquals(set, <int>{2})), isTrue);
      expect(members.any((set) => setEquals(set, <int>{3})), isTrue);
    });
  });
}
