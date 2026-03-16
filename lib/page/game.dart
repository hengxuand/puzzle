import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/game/puzzle_flame_game.dart';
import 'package:discovery_puzzle/page/welcome.dart';
import 'package:discovery_puzzle/state/puzzle_providers.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final PuzzleGameController _gameController;
  late final PuzzleFlameGame _flameGame;

  @override
  void initState() {
    super.initState();
    _gameController = Get.find<PuzzleGameController>();
    _flameGame = PuzzleFlameGame(controller: _gameController);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final gameController = _gameController;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey[600],
            child: Obx(() {
              final GameLevel? selectedLevel =
                  gameController.selectedLevel.value;

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedLevel == null
                        ? 'Puzzle Challenge'
                        : '${selectedLevel.name} (${selectedLevel.difficulty.displaySize})',
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    selectedLevel?.description ?? 'Prepare your puzzle board',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: ClipRRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GameWidget(game: _flameGame),
                            if (gameController.imageAsync.value == null)
                              const ColoredBox(
                                color: Color(0xFFB7AAA4),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              await gameController
                                  .applySuggestedLevelSelectionForMenu();
                              Get.offAll(() => const WelcomePage());
                            },
                            child: const Text(
                              'Go Back',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: gameController.isSolved.value
                                ? () async {
                                    await gameController
                                        .playSuggestedNextLevel();
                                  }
                                : null,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Play Next Level'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
