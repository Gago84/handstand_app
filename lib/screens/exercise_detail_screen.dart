import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/exercise.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/progress_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final int index;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.index,
  });

  @override
  State<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

// ================= TIMER =================
class TimerWidget extends StatefulWidget {
  final Function(int seconds)? onTimeUpdate;
  const TimerWidget({super.key, this.onTimeUpdate});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  int seconds = 0;
  Timer? timer;
  bool isRunning = false;

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => seconds++);
      widget.onTimeUpdate?.call(seconds);
    });
    setState(() => isRunning = true);
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      seconds = 0;
      isRunning = false;
    });
    widget.onTimeUpdate?.call(seconds);
  }

  String formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          formatTime(seconds),
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isRunning ? null : startTimer,
              child: const Text("Start"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isRunning ? pauseTimer : null,
              child: const Text("Pause"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: resetTimer,
              child: const Text("Reset"),
            ),
          ],
        ),
      ],
    );
  }
}

// ================= SCREEN =================
class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool isFullScreen = false;

  late YoutubePlayerController _controller;
  late String _currentVideoId;

  bool isDone = false;
  int currentSeconds = 0;
  bool warmupSaved = false;
  late int requiredSeconds;

  bool _wasPlaying = false; // 🔥 detect play/pause

  int getRequiredSeconds(int index) {
    switch (index) {
      case 0:
        return 5;
      case 1:
        return 15;
      case 2:
        return 20;
      case 3:
        return 25;
      default:
        return 10;
    }
  }

  @override
  void initState() {
    super.initState();

    requiredSeconds = getRequiredSeconds(widget.index);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _currentVideoId = widget.exercise.videoPortrait.isNotEmpty
        ? widget.exercise.videoPortrait
        : widget.exercise.videoLand;

    _controller = YoutubePlayerController(
      initialVideoId: _currentVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        hideControls: false,
        controlsVisibleAtStart: true,
      ),
    )..addListener(_videoListener); // 🔥 listener

    loadProgress();
  }

  void _videoListener() {
    if (!_controller.value.isReady) return;

    final isPlaying = _controller.value.isPlaying;

    // ▶️ PLAY → FULLSCREEN
    if (isPlaying && !_wasPlaying) {
      setState(() => isFullScreen = true);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    // ⏸ PAUSE → EXIT FULLSCREEN
    if (!isPlaying && _wasPlaying) {
      setState(() => isFullScreen = false);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    _wasPlaying = isPlaying;
  }

  void loadProgress() async {
    final done =
        await ProgressService.isDone("step_${widget.index}");
    setState(() => isDone = done);
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isFullScreen
          ? null
          : AppBar(title: Text(widget.exercise.title)),

      body: SafeArea(
        child: Column(
          children: [
            // 🎥 VIDEO
Expanded(
  child: ClipRect(
    child: SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 16 / 9,
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            bottomActions: const [],
          ),
        ),
      ),
    ),
  ),
),

            // TEXT
            if (!isFullScreen)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    "Track your training time and mark your progress",
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),

      // BOTTOM UI
      bottomNavigationBar: isFullScreen
          ? null
          : SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TimerWidget(
                      onTimeUpdate: (sec) async {
                        setState(() => currentSeconds = sec);

                        if (!warmupSaved &&
                            widget.exercise.title
                                .toLowerCase()
                                .contains("warm") &&
                            sec >= requiredSeconds) {
                          warmupSaved = true;
                          await ProgressService.saveWarmupTime();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text("How was this step?"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await ProgressService.saveFeedback(
                                widget.index, true);
                          },
                          child: const Text("👍 Good"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await ProgressService.saveFeedback(
                                widget.index, false);
                          },
                          child: const Text("😓 Need Practice"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentSeconds < requiredSeconds
                          ? "Remaining: ${requiredSeconds - currentSeconds}s"
                          : "Great job! You can mark this step as completed.",
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          (currentSeconds >= requiredSeconds && !isDone)
                              ? () async {
                                  await ProgressService.markDone(
                                      "step_${widget.index}");
                                  Navigator.pop(context);
                                }
                              : null,
                      child: Text(
                        currentSeconds < requiredSeconds
                            ? "Train at least $requiredSeconds seconds"
                            : (isDone
                                ? "Completed ✅"
                                : "Mark as Done"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}