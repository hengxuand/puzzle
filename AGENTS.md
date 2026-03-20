# AGENTS Guide - puzzle

## Scope and source notes
- This guide is derived from code and docs in this repo, including `README.md` and runtime/test files under `lib/` and `test/`.
- No prior agent-specific rule files were found in root (only default `README.md` content).

## Big picture architecture
- App bootstrap is in `lib/main.dart`: initializes `GetStorage`, configures global logging, locks portrait orientation, and mounts `GetMaterialApp`.
- Dependency wiring is centralized in `lib/state/puzzle_dependencies_binding.dart` using `Get.put(..., permanent: true)` for logic, services, and controllers.
- UI flow is 2-page: `WelcomePage` (`lib/page/welcome.dart`) -> `GamePage` (`lib/page/game.dart`) -> back to welcome.
- Game rendering is Flame-based: `PuzzleFlameGame` (`lib/game/puzzle_flame_game.dart`) mirrors GetX controller state into `PuzzleWorldComponent`.
- State ownership lives in `PuzzleGameController` (`lib/state/game/puzzle_game_controller.dart`); Flame components are mostly view/input adapters.
- Level progression is separate from board state: `GameLevelController` + `LevelStatusController` manage unlock/completion and selection.

## Data and control flow that matters
- Startup path: `main()` -> `PuzzleDependenciesBinding` -> `GameLevelController.onInit()` (`loadProgress`, `loadSelectedLevel`).
- Entering a level calls `PuzzleGameController.openLevel()`: sets level, loads asset image via `PuzzleImageLoader`, shuffles tiles with `PuzzleLogic`.
- Per-frame sync: `PuzzleFlameGame.update()` builds a `stateKey` from level id, board size, tiles, and drag state; `PuzzleWorldComponent.syncFromController()` only re-renders when changed.
- Cluster drag pipeline: Flame `TileComponent` drag callbacks -> `PuzzleWorldComponent` target projection -> `PuzzleGameController.canAcceptClusterDrop/moveClusterFromDrag`.
- Completion side effect: `_setBoardState()` detects solved transition and calls `GameLevelController.markLevelCompleted(...)` to persist unlock changes.
- Persistence boundary: `ProgressStorageService` serializes `LevelProgressSnapshot` and selected `GameLevel` JSON in GetStorage keys `level_progress_snapshot` and `selected_level`.

## Project-specific conventions
- Level IDs and group IDs are `int` (not strings); unlock logic assumes sequential IDs for "next level" (`level.id + 1`) inside a group.
- Canonical level catalog is static config in `lib/models/levels.dart`; first level in each group is seeded as unlocked in `_buildInitialGroupsFromConfig()`.
- Models are defensive to wire-format drift (`fromJson` accepts legacy string/int ids and list/map level layouts).
- Reactive style is GetX-heavy (`Rx`, `Rxn`, `ever`, `Obx`) with controller methods as mutation boundaries.
- Flame rendering avoids full rebuilds; components are reused and animated (`MoveEffect`) rather than recreated each frame.

## Developer workflows
- Install deps:
```bash
flutter pub get
```
- Run app:
```bash
flutter run
```
- Run tests (existing active tests are primarily logic-level):
```bash
flutter test
```
- Main validated test coverage is in `test/logic/puzzle_logic_test.dart`; `test/state/puzzle_game_controller_test.dart` is currently fully commented out.

## Integration points and change checklist
- Adding levels: update `lib/models/levels.dart` and ensure matching assets exist under `assets/levels/...` and are covered by `pubspec.yaml` asset directories.
- Changing board dimensions/difficulty: update `PuzzleDifficulty` and verify drag projection/snap behavior in `PuzzleWorldComponent` still feels correct.
- Changing persistence schema: keep backward compatibility in model `fromJson` methods (`GameLevel`, `LevelGroup`, `LevelProgressSnapshot`).
- Touching progression logic: verify `markLevelCompleted`, default selection (`_selectDefaultLevelForGroup`), and reset flow from `WelcomePage` remain consistent.
- Touching UI/game boundary: prefer controller API changes over direct Flame state mutation.

