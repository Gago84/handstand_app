import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class PrerequisiteScreen extends StatefulWidget {
  const PrerequisiteScreen({super.key});

  @override
  State<PrerequisiteScreen> createState() => _PrerequisiteScreenState();
}

class _PrerequisiteScreenState extends State<PrerequisiteScreen> {
  bool? _canPullUp;
  bool? _canPushUp;
  bool _showRequirements = false;

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
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _resetAnswers() {
    setState(() {
      _showRequirements = false;
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
                  : _buildQuestions(context),
            ),
          ),
        ],
      ),
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
                      question: 'Can you do 3 reps of regular pull up?',
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
                      question: 'Can you do 3 reps of regular push up?',
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
          ],
        );
      },
    );
  }

  Widget _buildRequirements(BuildContext context) {
    final requirements = <String>[
      if (_canPullUp == false) 'Resistance band pull up',
      if (_canPullUp == false) 'Negative pull up',
      if (_canPushUp == false) 'Incline push up',
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
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
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
                                      requirement,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
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
