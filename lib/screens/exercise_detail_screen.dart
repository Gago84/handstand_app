import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/exercise.dart';
import 'package:flutter/services.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late YoutubePlayerController _controller;
  late String _currentVideoId;

  @override
  void initState() {
    super.initState();

    // Cho phép xoay màn hình
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // default: portrait trước
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
  }

  @override
  void dispose() {
    _controller.dispose(); // 🔥 QUAN TRỌNG

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

    // 🔥 chỉ load lại khi video khác
    if (newVideoId.isNotEmpty && newVideoId != _currentVideoId) {
      _currentVideoId = newVideoId;
      _controller.load(newVideoId);
    }

    return Scaffold(
      appBar: isPortrait
          ? AppBar(title: Text(widget.exercise.title))
          : null, // 🔥 landscape ẩn appbar cho đẹp

      body: Center(
        child: AspectRatio(
          aspectRatio: isPortrait ? 9 / 16 : 16 / 9,
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
          ),
        ),
      ),
    );
  }
}