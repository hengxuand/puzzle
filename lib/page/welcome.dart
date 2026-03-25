import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:puzzle/config/app_config.dart';
import 'package:puzzle/game/welcome_selection_flame_game.dart';
import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/page/game.dart';
import 'package:puzzle/page/widgets/reset_levels_button.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final PuzzleGameController puzzleController;
  late final WelcomeSelectionFlameGame flameGame;

  @override
  void initState() {
    super.initState();
    puzzleController = Get.find<PuzzleGameController>();
    flameGame = WelcomeSelectionFlameGame(controller: puzzleController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Obx(() {
            final GameLevel? selectedLevel =
                puzzleController.selectedLevel.value;

            final bool hasGroups =
                (puzzleController.progressSnapshot.value?.groups.isNotEmpty ??
                false);

            if (!hasGroups) {
              return const SizedBox.shrink();
            }

            final bool isSelectedLevelCompleted =
                selectedLevel != null &&
                puzzleController.isCompleted(selectedLevel.id);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Story Puzzle',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a story to start your puzzle adventure!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GameWidget(game: flameGame),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: selectedLevel == null
                      ? null
                      : () async {
                          await puzzleController.openLevel(
                            selectedLevel,
                            reshuffle: !isSelectedLevelCompleted,
                          );
                          Get.to(() => GamePage());
                        },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      isSelectedLevelCompleted
                          ? 'View the puzzle'
                          : 'Solve the Puzzle',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                if (kDebugMode)
                  ResetLevelsButton(puzzleController: puzzleController),
                const SizedBox(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }
}
