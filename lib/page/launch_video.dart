import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:puzzle/page/welcome.dart';
import 'package:puzzle/theme/app_colors.dart';
import 'package:video_player/video_player.dart';

class LaunchVideoPage extends StatefulWidget {
  const LaunchVideoPage({super.key});

  @override
  State<LaunchVideoPage> createState() => _LaunchVideoPageState();
}

class _LaunchVideoPageState extends State<LaunchVideoPage> {
  static const String _launchVideoAssetPath = 'assets/intro/launcher.mp4';

  VideoPlayerController? _controller;
  Timer? _fallbackTimer;
  bool _didNavigate = false;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    _startVideo();
  }

  Future<void> _startVideo() async {
    final VideoPlayerController controller = VideoPlayerController.asset(
      _launchVideoAssetPath,
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller
        ..setLooping(false)
        ..addListener(_onPlaybackChanged)
        ..setVolume(1.0);

      await controller.play();

      setState(() {
        _controller = controller;
        _initializationError = null;
      });

      // Guard against plugin/device edge-cases where completion may never fire.
      final int durationMs = controller.value.duration.inMilliseconds;
      _fallbackTimer = Timer(
        Duration(milliseconds: durationMs > 0 ? durationMs + 1000 : 8000),
        _goToWelcome,
      );
    } catch (error, stackTrace) {
      debugPrint('Launch video failed to initialize: $error');
      debugPrintStack(stackTrace: stackTrace);
      await controller.dispose();
      if (!mounted) {
        return;
      }

      setState(() {
        _initializationError = error;
      });
    }
  }

  void _onPlaybackChanged() {
    final VideoPlayerController? controller = _controller;
    if (controller == null) {
      return;
    }

    final value = controller.value;
    if (!value.isInitialized) {
      return;
    }

    if (value.position >= value.duration && !value.isPlaying) {
      _goToWelcome();
    }
  }

  void _goToWelcome() {
    if (_didNavigate || !mounted) {
      return;
    }

    _didNavigate = true;
    Get.off(() => const WelcomePage());
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller?.removeListener(_onPlaybackChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;
    if (_initializationError != null) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: TextButton(
            onPressed: _goToWelcome,
            child: const Text('Continue'),
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
