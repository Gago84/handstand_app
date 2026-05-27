import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/routine.dart';

enum _SessionPhase { ready, exercise, rest, complete }

class RoutineSessionScreen extends StatefulWidget {
  const RoutineSessionScreen({
    super.key,
    required this.day,
    required this.steps,
  });

  final RoutineDay day;
  final List<RoutineSessionStep> steps;

  @override
  State<RoutineSessionScreen> createState() => _RoutineSessionScreenState();
}

class _RoutineSessionScreenState extends State<RoutineSessionScreen> {
  Timer? _timer;
  _SessionPhase _phase = _SessionPhase.ready;
  int _stepIndex = 0;
  int _remaining = 0;
  YoutubePlayerController? _youtubeController;

  RoutineSessionStep get _currentStep => widget.steps[_stepIndex];
  bool get _hasYoutubeVideo => _currentStep.item.videoId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _prepareVideo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _prepareVideo() {
    _youtubeController?.dispose();
    _youtubeController = null;

    if (_hasYoutubeVideo) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: _currentStep.item.videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
      if (mounted) setState(() {});
    }
  }

  void _startExercise() {
    _youtubeController?.play();

    if (!_currentStep.isTimed) {
      setState(() {
        _phase = _SessionPhase.exercise;
        _remaining = 0;
      });
      return;
    }

    _startCountdown(_currentStep.durationSeconds, _SessionPhase.exercise);
  }

  void _finishExercise() {
    _timer?.cancel();
    _youtubeController?.pause();

    if (_currentStep.restSeconds > 0 && _stepIndex < widget.steps.length - 1) {
      _startCountdown(_currentStep.restSeconds, _SessionPhase.rest);
      return;
    }

    _goToNextStep();
  }

  void _goToNextStep() {
    _timer?.cancel();

    if (_stepIndex >= widget.steps.length - 1) {
      setState(() {
        _phase = _SessionPhase.complete;
        _remaining = 0;
      });
      return;
    }

    setState(() {
      _stepIndex++;
      _phase = _SessionPhase.ready;
      _remaining = 0;
    });
    _prepareVideo();
  }

  void _startCountdown(int seconds, _SessionPhase phase) {
    _timer?.cancel();
    setState(() {
      _phase = phase;
      _remaining = seconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
        });

        if (phase == _SessionPhase.rest) {
          _goToNextStep();
        }
        return;
      }

      setState(() {
        _remaining--;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF101214),
        body: Center(
          child: Text(
            'No exercises found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101214),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101214),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.day.title),
      ),
      body: SafeArea(
        child: _phase == _SessionPhase.complete
            ? _CompleteView(onDone: () => Navigator.pop(context))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final videoHeight = (constraints.maxHeight * 0.36).clamp(
                    310.0,
                    440.0,
                  );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                    children: [
                      _ProgressHeader(
                        current: _stepIndex + 1,
                        total: widget.steps.length,
                        phase: _phase,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: videoHeight,
                        child: _VideoPanel(
                          key: ValueKey(
                            '${_currentStep.item.id}-${_currentStep.item.videoUrl}',
                          ),
                          youtubeController: _youtubeController,
                          videoUrl: _currentStep.item.videoUrl,
                          title: _currentStep.title,
                          description: _currentStep.item.description,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentStep.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Set ${_currentStep.setNumber}/${_currentStep.totalSets}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TimerPanel(
                        phase: _phase,
                        remaining: _remaining,
                        duration: _currentStep.durationSeconds,
                        effortLabel: _currentStep.effortLabel,
                        isTimed: _currentStep.isTimed,
                        restSeconds: _currentStep.restSeconds,
                      ),
                      const SizedBox(height: 18),
                      _ActionButton(
                        phase: _phase,
                        canMarkDone:
                            _phase == _SessionPhase.exercise &&
                            (!_currentStep.isTimed || _remaining == 0),
                        onStart: _startExercise,
                        onDone: _finishExercise,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.phase,
  });

  final int current;
  final int total;
  final _SessionPhase phase;

  @override
  Widget build(BuildContext context) {
    final label = switch (phase) {
      _SessionPhase.ready => 'Ready',
      _SessionPhase.exercise => 'Training',
      _SessionPhase.rest => 'Rest',
      _SessionPhase.complete => 'Complete',
    };

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Colors.orange),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$label  $current/$total',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _VideoPanel extends StatefulWidget {
  const _VideoPanel({
    super.key,
    required this.youtubeController,
    required this.videoUrl,
    required this.title,
    required this.description,
  });

  final YoutubePlayerController? youtubeController;
  final String videoUrl;
  final String title;
  final String description;

  @override
  State<_VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<_VideoPanel> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _isCaching = false;
  bool _isPreparingPlayback = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _VideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _resetHostedVideo();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  void _resetHostedVideo() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
    _initializeFuture = null;
    _isCaching = false;
    _isPreparingPlayback = false;
    _error = null;
  }

  Future<void> _playHostedVideo() async {
    if (widget.youtubeController != null || widget.videoUrl.isEmpty) {
      return;
    }

    final videoUrl = widget.videoUrl;

    try {
      setState(() {
        _isPreparingPlayback = true;
        _error = null;
      });

      final isAssetVideo = videoUrl.startsWith('assets/');
      final cachedFile = isAssetVideo
          ? null
          : await DefaultCacheManager().getFileFromCache(videoUrl);
      final controller = isAssetVideo
          ? VideoPlayerController.asset(videoUrl)
          : cachedFile == null
          ? VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          : VideoPlayerController.file(File(cachedFile.file.path));
      final initializeFuture = _initializeAndPlay(controller, videoUrl);

      _controller?.removeListener(_videoListener);
      await _controller?.dispose();
      controller.addListener(_videoListener);
      setState(() {
        _controller = controller;
        _initializeFuture = initializeFuture;
        _isPreparingPlayback = false;
        _isCaching = !isAssetVideo && cachedFile == null;
        _error = null;
      });

      if (!isAssetVideo && cachedFile == null) {
        _cacheInBackground(videoUrl);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparingPlayback = false;
        _isCaching = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _initializeAndPlay(
    VideoPlayerController controller,
    String videoUrl,
  ) async {
    await controller.initialize();
    await controller.setLooping(true);
    if (!mounted || widget.videoUrl != videoUrl) return;
    await controller.play();
  }

  Future<void> _cacheInBackground(String videoUrl) async {
    try {
      await DefaultCacheManager().downloadFile(videoUrl);
    } finally {
      if (!mounted || widget.videoUrl != videoUrl) return;
      setState(() {
        _isCaching = false;
      });
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: const Color(0xFF1B1F22),
        child: widget.youtubeController != null
            ? YoutubePlayer(
                controller: widget.youtubeController!,
                showVideoProgressIndicator: true,
              )
            : _controller != null
            ? FutureBuilder<void>(
                future: _initializeFuture,
                builder: (context, snapshot) {
                  if (_error != null) {
                    return _PlaceholderVideo(
                      title: widget.title,
                      description: 'Video could not load.',
                      icon: Icons.error_outline,
                    );
                  }

                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 58,
                        color: Colors.white.withValues(alpha: 0.88),
                        onPressed: () {
                          if (_controller!.value.isPlaying) {
                            _controller!.pause();
                          } else {
                            _controller!.play();
                          }
                        },
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                      ),
                      if (_isCaching)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Caching offline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
            : _isPreparingPlayback
            ? const _VideoLoading(label: 'Preparing video')
            : Padding(
                padding: const EdgeInsets.all(20),
                child: _PlaceholderVideo(
                  title: widget.title,
                  description: widget.description,
                  icon: Icons.play_circle_outline,
                  onTap: widget.videoUrl.isEmpty ? null : _playHostedVideo,
                ),
              ),
      ),
    );
  }
}

class _VideoLoading extends StatelessWidget {
  const _VideoLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderVideo extends StatelessWidget {
  const _PlaceholderVideo({
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white38, size: 56),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(height: 10),
              const Text(
                'Tap to stream and cache',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.phase,
    required this.remaining,
    required this.duration,
    required this.effortLabel,
    required this.isTimed,
    required this.restSeconds,
  });

  final _SessionPhase phase;
  final int remaining;
  final int duration;
  final String effortLabel;
  final bool isTimed;
  final int restSeconds;

  @override
  Widget build(BuildContext context) {
    final title = switch (phase) {
      _SessionPhase.ready => 'Exercise time',
      _SessionPhase.exercise => 'Countdown',
      _SessionPhase.rest => 'Rest countdown',
      _SessionPhase.complete => 'Done',
    };
    final label = phase == _SessionPhase.rest
        ? _format(remaining)
        : isTimed
        ? _format(phase == _SessionPhase.ready ? duration : remaining)
        : effortLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rest after done: ${restSeconds}s',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  String _format(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.phase,
    required this.canMarkDone,
    required this.onStart,
    required this.onDone,
  });

  final _SessionPhase phase;
  final bool canMarkDone;
  final VoidCallback onStart;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isReady = phase == _SessionPhase.ready;
    final isRest = phase == _SessionPhase.rest;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isRest
              ? Colors.grey
              : (isReady || canMarkDone ? Colors.orange : Colors.grey[700]),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isRest
            ? null
            : (isReady
                  ? onStart
                  : canMarkDone
                  ? onDone
                  : null),
        icon: Icon(isReady ? Icons.play_arrow : Icons.check),
        label: Text(
          isReady
              ? 'Start'
              : isRest
              ? 'Resting...'
              : 'Done',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.orange, size: 72),
            const SizedBox(height: 18),
            const Text(
              'Session Complete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Good work. Come back tomorrow for the next routine.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
              ),
              onPressed: onDone,
              child: const Text('Back to Week Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
