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
                  Visibility(
                    visible: gameController.isSolved.value,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x1A2E7D32),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x552E7D32)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Great job! You solved it.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (gameController.suggestedNextLevelName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Unlocked: ${gameController.suggestedNextLevelName}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.green[900],
                                  ),
                                ),
                              ),
                            if (gameController.suggestedNextLevelName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await gameController.playSuggestedNextLevel();
                                  },
                                  icon: const Icon(Icons.skip_next),
                                  label: const Text('Play Next Level'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await gameController.applySuggestedLevelSelectionForMenu();
                          Get.offAll(() => const WelcomePage());
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          child: Text(
                            'Go Back',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
