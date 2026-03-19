import 'package:discovery_puzzle/page/welcome.dart';
import 'package:discovery_puzzle/state/puzzle_dependencies_binding.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logging/logging.dart';

Future<void> main() async {
  _configureLogging();
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Flame.device.fullScreen();
  Flame.device.setPortrait();
  runApp(const DiscoveryPuzzleApp());
}

void _configureLogging() {
  Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.time.toIso8601String()} ${record.loggerName}: ${record.message}',
    );
  });
}

class DiscoveryPuzzleApp extends StatelessWidget {
  const DiscoveryPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discovery Puzzle',
      initialBinding: PuzzleDependenciesBinding(),
      builder: (context, child) => SafeArea(child: child!),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: WelcomePage(),
    );
  }
}
