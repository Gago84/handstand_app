import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/exercise.dart';
import 'package:flutter/services.dart';

// 🔥 IMPORT 2 FILE MỚI
import '../widgets/timer_widget.dart';
import '../services/progress_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});
  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late YoutubePlayerController _controller;
  late String _currentVideoId;

  bool isDone = false;

  @override
  void initState() {
    super.initState();

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

  // 🔥 LOAD PROGRESS
  void loadProgress() async {
    final done = await ProgressService.isDone(widget.exercise.title);
    setState(() => isDone = done);
  }

  // 🔥 MARK DONE
  void markDone() async {
    await ProgressService.markDone(widget.exercise.title);
    setState(() => isDone = true);
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

    final newVideoId = isPortrait
        ? widget.exercise.videoPortrait
        : widget.exercise.videoLand;

    if (newVideoId.isNotEmpty && newVideoId != _currentVideoId) {
      _currentVideoId = newVideoId;
      _controller.load(newVideoId);
    }

    return Scaffold(
      appBar: isPortrait
          ? AppBar(title: Text(widget.exercise.title))
          : null,

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🎥 VIDEO
            AspectRatio(
              aspectRatio: isPortrait ? 9 / 16 : 16 / 9,
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
              ),
            ),

            const SizedBox(height: 20),

            // 🧠 TEXT GIÚP REVIEWER HIỂU APP
            const Text(
              "Track your training time and mark your progress",
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 20),

            // ⏱ TIMER (file riêng)
            const TimerWidget(),

            const SizedBox(height: 20),

            // ✅ MARK DONE
            ElevatedButton(
              onPressed: isDone ? null : markDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? Colors.green : null,
              ),
              child: Text(isDone ? "Completed ✅" : "Mark as Done"),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}