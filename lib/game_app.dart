import 'package:discovery_puzzle/constants.dart';
import 'package:discovery_puzzle/puzzle_game.dart';
import 'package:discovery_puzzle/state/providers/puzzle_dependencies_binding.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  late final PuzzleGame game;

  @override
  void initState() {
    super.initState();
    game = PuzzleGame();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'Discovery Puzzle',
      initialBinding: PuzzleDependenciesBinding(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.yellow,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: FittedBox(
              child: SizedBox(
                width: gameWidth,
                height: gameHeight,
                child: GameWidget(game: game),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
