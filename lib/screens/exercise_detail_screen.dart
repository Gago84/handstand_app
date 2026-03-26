import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/exercise.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// 🔥 IMPORT
import '../services/progress_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final int index; // 🔥 ADD THIS
  const ExerciseDetailScreen({super.key, required this.exercise, required this.index});

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
              fontSize: 40, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isRunning ? null : startTimer,
              child: const Text("Start"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: isRunning ? pauseTimer : null,
              child: const Text("Pause"),
            ),
            const SizedBox(width: 10),
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
    // 🔥 ADD HERE (NGAY DƯỚI CLASS)
  int getRequiredSeconds(int index) {
    switch (index) {
      case 0: return 5;     // warmup (test)
      case 1: return 15;    // step 2 (test)
      case 2: return 20;
      case 3: return 25;
      default: return 10;
      }
  }
  late YoutubePlayerController _controller;
  late String _currentVideoId;

  bool isDone = false;

  int currentSeconds = 0;

  // 🔥 ADD THIS (tránh save nhiều lần)
  bool warmupSaved = false;
    // 🔥 ADD THIS LINE (CHÍNH XÁC Ở ĐÂY)
  late int requiredSeconds;

  @override
  void initState() {
    super.initState();

    // 🔥 ADD THIS LINE
    requiredSeconds = getRequiredSeconds(widget.index);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _currentVideoId = widget.exercise.videoPortrait.isNotEmpty
        ? widget.exercise.videoPortrait
        : widget.exercise.videoLand;

    _controller = YoutubePlayerController(
      initialVideoId: _currentVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );

    loadProgress();
  }

  void loadProgress() async {
    final done = await ProgressService.isDone("step_${widget.index}");
    setState(() => isDone = done);
  }

  @override
  void dispose() {
    _controller.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: isPortrait
          ? AppBar(title: Text(widget.exercise.title))
          : null,

      body: Column(
        children: [
          Expanded(
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Track your training time and mark your progress",
          ),
          const SizedBox(height: 10),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
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
                  setState(() {
                    currentSeconds = sec;
                  });

                  // 🔥 ADD THIS BLOCK (QUAN TRỌNG NHẤT)
                  if (!warmupSaved &&
                      widget.exercise.title.toLowerCase().contains("warm") &&
                      sec >= requiredSeconds) {
                    warmupSaved = true;
                    await ProgressService.saveWarmupTime();

                    print("🔥 Warmup DONE saved!");
                  }
                },
              ),
              const SizedBox(height: 16),

              Text("How do you feel?"),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await ProgressService.saveFeedback(widget.index, true);
                    },
                    child: const Text("👍 Good"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await ProgressService.saveFeedback(widget.index, false);
                    },
                    child: const Text("😓 Need Practice"),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                currentSeconds < requiredSeconds
                    ? "Remaining: ${requiredSeconds - currentSeconds}s"
                    : "Great job! You can mark this step as completed.",
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: (currentSeconds >= requiredSeconds && !isDone)
                    ? () async {
                        // 🔥 SAVE STEP (QUAN TRỌNG NHẤT)
                        await ProgressService.markDone("step_${widget.index}");

                        print("🔥 DONE step_${widget.index}");

                        // 🔥 QUAY VỀ HOME
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  currentSeconds < requiredSeconds
                      ? "Train at least ${requiredSeconds} seconds"
                      : (isDone ? "Completed ✅" : "Mark as Done"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}