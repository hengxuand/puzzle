import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:puzzle/config/app_config.dart';
import 'package:puzzle/game/puzzle_flame_game.dart';
import 'package:puzzle/page/welcome.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final PuzzleGameController gameController;
  late final PuzzleFlameGame flameGame;

  @override
  void initState() {
    super.initState();
    gameController = Get.find<PuzzleGameController>();
    flameGame = PuzzleFlameGame(controller: gameController);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: AppConfig.backgroundColor,
            child: Obx(() {
              final selectedLevel = gameController.selectedLevel.value;

              if (selectedLevel == null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No level selected.',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Get.off(() => const WelcomePage()),
                      child: const Text('Go Back'),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedLevel.name} (${selectedLevel.difficulty.displaySize})',
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    selectedLevel.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: ClipRRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GameWidget(game: flameGame),
                            if (gameController.imageAsync.value == null)
                              const ColoredBox(
                                color: AppConfig.backgroundColor,
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
                      const Spacer(),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Go Back',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
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
