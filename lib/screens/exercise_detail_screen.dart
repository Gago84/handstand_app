import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/exercise.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
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
    HapticFeedback.lightImpact();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => seconds++);
      widget.onTimeUpdate?.call(seconds);
    });
    setState(() => isRunning = true);
  }

  void pauseTimer() {
    HapticFeedback.lightImpact();
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    HapticFeedback.lightImpact();
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

  Widget _pillButton(String text, VoidCallback? onTap,
      {bool isSecondary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSecondary ? Colors.grey[200] : Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSecondary ? Colors.black : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
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
            fontSize: 44,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _pillButton("Start", isRunning ? null : startTimer),
            _pillButton("Pause", isRunning ? pauseTimer : null),
            _pillButton("Reset", resetTimer, isSecondary: true),
          ],
        ),
      ],
    );
  }
}

// ================= SCREEN =================
class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool isFullScreen = false;
  bool? isGoodSelected;
  bool hasSavedFeedback = false; // 👈 quan trọng

  late YoutubePlayerController _controller;
  late String _currentVideoId;

  bool isDone = false;
  int currentSeconds = 0;
  bool warmupSaved = false;
  late int requiredSeconds;

  bool _wasPlaying = false;

  int getRequiredSeconds(int index) {
    switch (index) {
      case 0:
        return 5;
      case 1:
        return 10;
      case 2:
        return 10;
      case 3:
        return 10;
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
    )..addListener(_videoListener);

    loadProgress();
  }

  void _videoListener() {
    if (!_controller.value.isReady) return;

    final isPlaying = _controller.value.isPlaying;

    if (isPlaying && !_wasPlaying) {
      setState(() => isFullScreen = true);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

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

Widget _segment(String text, bool isGood) {
  final isSelected = isGoodSelected == isGood;

  return GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();

      setState(() {
        isGoodSelected = isGood; // ✅ chỉ update UI
      });
    },
    child: AnimatedScale(
      scale: isSelected ? 1.05 : 1,
      duration: const Duration(milliseconds: 150),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  )
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
  );
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
            Expanded(
              child: ClipRect(
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.cover,
alignment: const Alignment(0, -0.5),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height:
                          MediaQuery.of(context).size.width * 16 / 9,
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
            if (!isFullScreen)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    "Track your training time and mark your progress",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),

      // ================= APPLE STYLE BOTTOM =================
      bottomNavigationBar: isFullScreen
          ? null
          : SafeArea(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    color: Colors.white.withOpacity(0.7),
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
                              await ProgressService
                                  .saveWarmupTime();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          "How was this step?",
                          style: TextStyle(
                              fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius:
                                BorderRadius.circular(25),
                          ),
                          child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    _segment("👍 Good", true),
    const SizedBox(width: 4),
    _segment("😓 Practice", false),
  ],
),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          currentSeconds < requiredSeconds
                              ? "Keep going • ${requiredSeconds - currentSeconds}s left"
                              : isGoodSelected == null
    ? "Please select feedback to continue"
    : "Nice work 🎉",
                          style: TextStyle(
                              color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 12),

                        GestureDetector(
onTap: (currentSeconds >= requiredSeconds &&
        !isDone &&
        isGoodSelected != null)
    ? () async {
        HapticFeedback.mediumImpact();

        // ✅ SAVE feedback tại đây (1 lần duy nhất)
        if (isGoodSelected != null) {
          await ProgressService.saveFeedback(
              widget.index, isGoodSelected!);
        }

        await ProgressService.markDone("step_${widget.index}");

        Navigator.pop(context);
      }
    : null,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 14),
                            decoration: BoxDecoration(
                              color: (currentSeconds >=
                                          requiredSeconds &&
                                      !isDone)
                                  ? Colors.black
                                  : Colors.grey[300],
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                currentSeconds <
                                        requiredSeconds
                                    ? "Train at least $requiredSeconds seconds"
                                    : (isDone
                                        ? "Completed ✅"
                                        : "Mark as Done"),
                                style: TextStyle(
                                  color: (currentSeconds >=
                                              requiredSeconds &&
                                          !isDone)
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}