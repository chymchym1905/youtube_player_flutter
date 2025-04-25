import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/youtube_player_controller.dart';
import '../player_params.dart';
import 'youtube_player.dart';

/// A widget that plays Youtube Video is full screen mode.
///
/// See also:
///
///  * [YoutubePlayer], which play or stream Youtube Videos in normal mode.
class FullscreenYoutubePlayer extends StatefulWidget {
  /// Creates an instance of [FullscreenYoutubePlayer].
  const FullscreenYoutubePlayer({
    super.key,
    required this.videoId,
    this.autoPlay = true,
    this.goRouter = false,
    this.startSeconds,
    this.endSeconds,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.backgroundColor,
  });

  /// The YouTube Video ID.
  final String videoId;

  /// Whether the video should play automatically.
  final bool autoPlay;

  /// Whether the app is using a [GoRouter].
  final bool goRouter;

  /// The time in seconds when the video should start from.
  final double? startSeconds;

  /// The time in seconds when the video should end at.
  final double? endSeconds;

  /// Which gestures should be consumed by the youtube player.
  ///
  /// It is possible for other gesture recognizers to be competing with the player on pointer
  /// events, e.g if the player is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The player will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// By default vertical and horizontal gestures are absorbed by the player.
  /// Passing an empty set will ignore the defaults.
  ///
  /// This is ignored on web.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The background color of the [WebView].
  ///
  /// Default to [ColorScheme.surface].
  final Color? backgroundColor;

  @override
  State<FullscreenYoutubePlayer> createState() {
    return _FullscreenYoutubePlayerState();
  }

  /// Launches the [FullscreenYoutubePlayer].
  ///
  /// Returns the time in seconds at which the player was popped.
  static Future<double?> launch(
    BuildContext context, {
    required String videoId,
    bool autoPlay = true,
    bool goRouter = false,
    double? startSeconds,
    double? endSeconds,
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
        const <Factory<OneSequenceGestureRecognizer>>{},
    Color? backgroundColor,
  }) {
    return Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FullscreenYoutubePlayer(
            autoPlay: autoPlay,
            goRouter: goRouter,
            videoId: videoId,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            gestureRecognizers: gestureRecognizers,
            backgroundColor: backgroundColor,
          );
        },
      ),
    );
  }
}

class _FullscreenYoutubePlayerState extends State<FullscreenYoutubePlayer> {
  late final YoutubePlayerController _controller;
  int callCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      startSeconds: widget.startSeconds,
      autoPlay: widget.autoPlay,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    )..setFullScreenListener((_) async {
        final currentTime = await _controller.currentTime;
        callCount++;
        if (!mounted || !context.mounted || callCount > 1) return;
        Navigator.pop(context, currentTime);
        _resetOrientation();
        _controller.close();
        
      });

    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final player = YoutubePlayer(
        controller: _controller,
        aspectRatio: MediaQuery.of(context).size.aspectRatio,
        backgroundColor: widget.backgroundColor,
        gestureRecognizers: widget.gestureRecognizers,
      );
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _controller.exitFullScreen();
          },
          child: player,
        ),
      );
    }
    if (widget.goRouter) {
      return BackButtonListener(
        child: player,
        onBackButtonPressed: () async {
        final route = ModalRoute.of(context);
        if (callCount > 1 || route?.isCurrent == false) return true;
        _controller.exitFullScreen();
        return true;
        },
      );
    }
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _controller.exitFullScreen();
      },
      child: player,
    );
  }

  @override
  void dispose() {
    callCount = 0;
    super.dispose();
  }

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
