import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/premium_gate.dart';
import '../data/routine_service.dart';
import 'home_screen.dart';
import 'premium_screen.dart';

enum _Gender { female, male }

enum _RepRange {
  zero('0 reps', RoutineLevel.beginner),
  oneToThree('1–3 reps', RoutineLevel.beginner),
  fourToSix('4–6 reps', RoutineLevel.intermediate),
  sevenToTen('7–10 reps', RoutineLevel.advance);

  const _RepRange(this.label, this.level);

  final String label;
  final RoutineLevel level;
}

class PrerequisiteScreen extends StatefulWidget {
  const PrerequisiteScreen({super.key});

  @override
  State<PrerequisiteScreen> createState() => _PrerequisiteScreenState();
}

class _PrerequisiteScreenState extends State<PrerequisiteScreen> {
  _Gender? _gender;
  _RepRange? _pullUps;
  _RepRange? _pushUps;
  bool _isCreatingPlan = false;

  bool get _isComplete =>
      _gender != null && _pullUps != null && _pushUps != null;

  RoutineLevel get _initialLevel {
    final pullLevel = _pullUps!.level;
    final pushLevel = _pushUps!.level;
    return pullLevel.index <= pushLevel.index ? pullLevel : pushLevel;
  }

  Future<void> _continue() async {
    if (!_isComplete || _isCreatingPlan) return;

    final basicPassed =
        _pullUps != _RepRange.zero && _pushUps != _RepRange.zero;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('user_gender_v1', _gender!.name),
      prefs.setString('initial_pull_up_range_v1', _pullUps!.name),
      prefs.setString('initial_push_up_range_v1', _pushUps!.name),
      prefs.setString('routine_level_v1', _initialLevel.name),
      prefs.setBool('basic_strength_passed_v1', basicPassed),
      prefs.setBool('initial_requirements_passed', true),
    ]);

    if (!mounted) return;
    setState(() => _isCreatingPlan = true);
    await Future<void>.delayed(const Duration(seconds: 2));

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
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
          SafeArea(
            child: _isCreatingPlan
                ? const _CreatingPlanView()
                : _buildQuestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Let’s Personalize Your Plan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Three quick questions to choose your starting level.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuestionCard(
                    number: 1,
                    question: 'What is your gender?',
                    child: Row(
                      children: [
                        Expanded(
                          child: _ChoiceButton(
                            label: 'Female',
                            selected: _gender == _Gender.female,
                            onTap: () =>
                                setState(() => _gender = _Gender.female),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChoiceButton(
                            label: 'Male',
                            selected: _gender == _Gender.male,
                            onTap: () => setState(() => _gender = _Gender.male),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuestionCard(
                    number: 2,
                    question: 'How many pull-ups can you do?',
                    child: _RangeChoices(
                      value: _pullUps,
                      onChanged: (value) => setState(() => _pullUps = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuestionCard(
                    number: 3,
                    question: 'How many push-ups can you do?',
                    child: _RangeChoices(
                      value: _pushUps,
                      onChanged: (value) => setState(() => _pushUps = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isComplete ? _continue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Create My Plan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.child,
  });

  final int number;
  final String question;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $question',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RangeChoices extends StatelessWidget {
  const _RangeChoices({required this.value, required this.onChanged});

  final _RepRange? value;
  final ValueChanged<_RepRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final range in _RepRange.values)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 82) / 2,
            child: _ChoiceButton(
              label: range.label,
              selected: value == range,
              onTap: () => onChanged(range),
            ),
          ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.orange : Colors.white10,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Colors.orangeAccent : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatingPlanView extends StatelessWidget {
  const _CreatingPlanView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 5,
              ),
            ),
            SizedBox(height: 28),
            Text(
              'Designing your workout plan…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Matching the program to your current strength.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
