import 'package:discovery_puzzle/logic/puzzle_logic.dart';
import 'package:discovery_puzzle/service/puzzle_image_loader.dart';
import 'package:discovery_puzzle/state/game/puzzle_game_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_controller.dart';
import 'package:get/get.dart';

class PuzzleDependenciesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PuzzleLogic(), permanent: true);
    Get.put(LevelProgressController(), permanent: true);
    Get.put(const PuzzleImageLoader(), permanent: true);
    Get.put(PuzzleGameController(), permanent: true);
  }
}
