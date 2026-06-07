import 'dart:io';
import 'dart:ui';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../config/premium_gate.dart';
import 'home_screen.dart';
import 'premium_screen.dart';

class PrerequisiteScreen extends StatefulWidget {
  const PrerequisiteScreen({super.key});

  @override
  State<PrerequisiteScreen> createState() => _PrerequisiteScreenState();
}

class _PrerequisiteScreenState extends State<PrerequisiteScreen> {
  _Gender? _gender;
  bool? _canPullUp;
  bool? _canPushUp;
  bool _showRequirements = false;

  int get _requiredReps => _gender == _Gender.female ? 1 : 3;
  String get _repLabel => _requiredReps == 1 ? 'rep' : 'reps';
  bool get _answered => _canPullUp != null && _canPushUp != null;
  bool get _canAccessProgram => _canPullUp == true && _canPushUp == true;

  Future<void> _continue() async {
    if (!_answered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer both questions')),
      );
      return;
    }

    if (!_canAccessProgram) {
      setState(() {
        _showRequirements = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('initial_requirements_passed', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumGate.bypassForLocalTesting
            ? const HomeScreen()
            : const PremiumScreen(requirePurchase: true),
      ),
    );
  }

  void _resetAnswers() {
    setState(() {
      _showRequirements = false;
    });
  }

  void _selectGender(_Gender gender) {
    setState(() {
      _gender = gender;
      _canPullUp = null;
      _canPushUp = null;
    });
  }

  void _changeGender() {
    setState(() {
      _gender = null;
      _canPullUp = null;
      _canPushUp = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/front-por.jpg', fit: BoxFit.cover),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: _showRequirements
                  ? _buildRequirements(context)
                  : _gender == null
                  ? _buildGenderQuestion(context)
                  : _buildQuestions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderQuestion(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 760;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isCompact ? 8 : 24),
                    Icon(
                      Icons.person_outline,
                      size: isCompact ? 54 : 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: isCompact ? 18 : 24),
                    const Text(
                      'Tell Us About Yourself',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'What is your gender?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isCompact ? 24 : 36),
                    Row(
                      children: [
                        Expanded(
                          child: _AnswerButton(
                            label: 'Female',
                            selected: false,
                            onPressed: () => _selectGender(_Gender.female),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnswerButton(
                            label: 'Male',
                            selected: false,
                            onPressed: () => _selectGender(_Gender.male),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 760;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isCompact ? 8 : 24),
                    Icon(
                      Icons.fact_check_outlined,
                      size: isCompact ? 54 : 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: isCompact ? 18 : 24),
                    const Text(
                      'Initial Requirements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Answer these two questions before starting the program.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isCompact ? 24 : 36),
                    _QuestionBlock(
                      question:
                          'Can you do $_requiredReps $_repLabel of regular pull up?',
                      compact: isCompact,
                      value: _canPullUp,
                      onChanged: (value) {
                        setState(() {
                          _canPullUp = value;
                        });
                      },
                    ),
                    SizedBox(height: isCompact ? 16 : 20),
                    _QuestionBlock(
                      question:
                          'Can you do $_requiredReps $_repLabel of regular push up?',
                      compact: isCompact,
                      value: _canPushUp,
                      onChanged: (value) {
                        setState(() {
                          _canPushUp = value;
                        });
                      },
                    ),
                    SizedBox(height: isCompact ? 16 : 24),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _continue,
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            TextButton(
              onPressed: _changeGender,
              child: const Text(
                'Change gender',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequirements(BuildContext context) {
    final requirements = <_RequirementPractice>[
      if (_canPullUp == false) _requirementPractices[0],
      if (_canPullUp == false) _requirementPractices[1],
      if (_canPushUp == false) _requirementPractices[2],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 760;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isCompact ? 8 : 24),
                    Icon(
                      Icons.lock_outline,
                      size: isCompact ? 54 : 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: isCompact ? 18 : 24),
                    const Text(
                      'Build Your Foundation First',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Come back when you pass the initial requirements.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isCompact ? 24 : 28),
                    Container(
                      padding: EdgeInsets.all(isCompact ? 16 : 18),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Required practice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (final requirement in requirements)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _RequirementVideoCard(
                                practice: requirement,
                                compact: isCompact,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: isCompact ? 16 : 24),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _resetAnswers,
                child: const Text(
                  'Answer Again',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _Gender { female, male }

const _requirementPractices = <_RequirementPractice>[
  _RequirementPractice(
    title: 'Resistance band pull up',
    description:
        'Use the band to reduce bodyweight and practice the full pull-up range.',
    videoUrl:
        'https://firebasestorage.googleapis.com/v0/b/banana-57559.firebasestorage.app/o/exercise%2Fbasic-equipment%2Frequirements%2Fresistance-band-pull-up.mp4?alt=media&token=70abddb9-c0a0-40ee-9120-7fc933669b70',
  ),
  _RequirementPractice(
    title: 'Negative pull up',
    description:
        'Start at the top of the pull up, then lower slowly with control.',
    videoUrl:
        'https://firebasestorage.googleapis.com/v0/b/banana-57559.firebasestorage.app/o/exercise%2Fbasic-equipment%2Frequirements%2Fnegative-pull-up.mp4?alt=media&token=fdcd590b-d37d-4035-a783-aa057c450a78',
  ),
  _RequirementPractice(
    title: 'Incline push up',
    description:
        'Place your hands on a raised surface to make pushups easier while building strength.',
    videoUrl:
        'https://firebasestorage.googleapis.com/v0/b/banana-57559.firebasestorage.app/o/exercise%2Fbasic-equipment%2Frequirements%2Fincline-push-up.mp4?alt=media&token=70c68a6f-5565-455e-b3bb-052587ca625e',
  ),
];

class _RequirementPractice {
  const _RequirementPractice({
    required this.title,
    required this.description,
    required this.videoUrl,
  });

  final String title;
  final String description;
  final String videoUrl;
}

class _RequirementVideoCard extends StatefulWidget {
  const _RequirementVideoCard({required this.practice, required this.compact});

  final _RequirementPractice practice;
  final bool compact;

  @override
  State<_RequirementVideoCard> createState() => _RequirementVideoCardState();
}

class _RequirementVideoCardState extends State<_RequirementVideoCard> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _isCaching = false;
  bool _isPreparingPlayback = false;
  String? _error;

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _playVideo() async {
    if (_controller != null || _isPreparingPlayback) {
      return;
    }

    try {
      setState(() {
        _isPreparingPlayback = true;
        _isCaching = false;
        _error = null;
      });

      final cachedFile = await DefaultCacheManager().getFileFromCache(
        widget.practice.videoUrl,
      );
      final controller = cachedFile == null
          ? VideoPlayerController.networkUrl(
              Uri.parse(widget.practice.videoUrl),
            )
          : VideoPlayerController.file(File(cachedFile.file.path));
      final initializeFuture = _initializeAndPlay(controller);

      controller.addListener(_videoListener);

      setState(() {
        _controller = controller;
        _initializeFuture = initializeFuture;
        _isPreparingPlayback = false;
        _isCaching = cachedFile == null;
      });

      if (cachedFile == null) {
        _cacheInBackground(widget.practice.videoUrl);
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

  Future<void> _initializeAndPlay(VideoPlayerController controller) async {
    await controller.initialize();
    await controller.setLooping(true);
    if (!mounted) return;
    await controller.play();
  }

  Future<void> _cacheInBackground(String videoUrl) async {
    try {
      await DefaultCacheManager().downloadFile(videoUrl);
    } finally {
      if (mounted && widget.practice.videoUrl == videoUrl) {
        setState(() {
          _isCaching = false;
        });
      }
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final videoHeight = widget.compact ? 210.0 : 260.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.practice.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.practice.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: videoHeight,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: const Color(0xFF111513),
                child: _buildVideoContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_error != null) {
      return const _RequirementVideoPlaceholder(
        icon: Icons.error_outline,
        label: 'Video could not load',
      );
    }

    if (_controller == null) {
      if (_isPreparingPlayback) {
        return const Center(child: CircularProgressIndicator());
      }

      return _RequirementVideoPlaceholder(
        icon: Icons.play_circle_outline,
        label: 'Watch instruction video',
        onTap: _playVideo,
      );
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _RequirementVideoPlaceholder(
            icon: Icons.error_outline,
            label: 'Video could not load',
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
              iconSize: 56,
              color: Colors.white.withValues(alpha: 0.9),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Caching offline',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RequirementVideoPlaceholder extends StatelessWidget {
  const _RequirementVideoPlaceholder({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 52),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.question,
    this.compact = false,
    required this.value,
    required this.onChanged,
  });

  final String question;
  final bool compact;
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          SizedBox(height: compact ? 14 : 16),
          Row(
            children: [
              Expanded(
                child: _AnswerButton(
                  label: 'Yes',
                  selected: value == true,
                  onPressed: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnswerButton(
                  label: 'No',
                  selected: value == false,
                  onPressed: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.black : Colors.white,
        backgroundColor: selected ? Colors.orange : Colors.transparent,
        side: BorderSide(
          color: selected ? Colors.orange : Colors.white54,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
