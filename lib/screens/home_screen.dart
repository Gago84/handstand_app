import 'package:flutter/material.dart';

import '../data/routine_service.dart';
import '../models/routine.dart';
import 'premium_screen.dart';
import 'routine_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RoutineService _routineService = RoutineService();
  late Future<RoutinePlan> _planFuture;
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _planFuture = _routineService.loadPlan();
  }

  Future<void> _openPremium() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
    _resetSelectedDay();
  }

  Future<void> _openSession(
    RoutineDay day,
    List<RoutineSessionStep> steps, {
    int initialStepIndex = 0,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineSessionScreen(
          day: day,
          steps: steps,
          initialStepIndex: initialStepIndex,
        ),
      ),
    );
    _resetSelectedDay();
  }

  void _resetSelectedDay() {
    if (!mounted || _selectedDayIndex == null) return;
    setState(() {
      _selectedDayIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101214),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101214),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Weekly Routine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Premium',
            color: Colors.orange,
            icon: const Icon(Icons.workspace_premium),
            onPressed: _openPremium,
          ),
        ],
      ),
      body: FutureBuilder<RoutinePlan>(
        future: _planFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off,
              title: 'Could not load routine',
              message: snapshot.error.toString(),
              actionLabel: 'Try Again',
              onAction: () {
                setState(() {
                  _planFuture = _routineService.loadPlan();
                });
              },
            );
          }

          final plan = snapshot.data;
          if (plan == null || plan.days.isEmpty) {
            return const _MessageState(
              icon: Icons.event_busy,
              title: 'No routine found',
              message: 'Add a routine document in Firebase to start training.',
            );
          }

          final today = plan.today;
          final selectedDay = plan.days.firstWhere(
            (day) => day.index == _selectedDayIndex,
            orElse: () => today,
          );
          final steps = _routineService.buildSessionSteps(
            selectedDay,
            plan.exerciseItems,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SelectedDayHeader(
                day: selectedDay,
                isToday: selectedDay.index == today.index,
              ),
              const SizedBox(height: 16),
              _WeekTable(
                days: plan.days,
                selectedDay: selectedDay,
                onSelected: (day) {
                  setState(() {
                    _selectedDayIndex = day.index;
                  });
                },
              ),
              const SizedBox(height: 18),
              _SelectedWorkoutCard(
                day: selectedDay,
                steps: steps,
                isToday: selectedDay.index == today.index,
                onStart: selectedDay.isRestDay || steps.isEmpty
                    ? null
                    : () => _openSession(selectedDay, steps),
                onStepSelected: (index) =>
                    _openSession(selectedDay, steps, initialStepIndex: index),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({required this.day, required this.isToday});

  final RoutineDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday ? 'Today' : 'Selected Day',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            day.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            day.isRestDay
                ? 'Rest and recover.'
                : '${day.sets} sets • ${day.rep} • Rest ${day.restSeconds}s',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _WeekTable extends StatelessWidget {
  const _WeekTable({
    required this.days,
    required this.selectedDay,
    required this.onSelected,
  });

  final List<RoutineDay> days;
  final RoutineDay selectedDay;
  final ValueChanged<RoutineDay> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171A1D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Week Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final day in days)
                    _DayColumn(
                      day: day,
                      selected: day.index == selectedDay.index,
                      onTap: () => onSelected(day),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final RoutineDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? Colors.orange : const Color(0xFF22262A),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 132,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.orangeAccent : Colors.white10,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weekdayLabel(day.index),
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  day.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  day.isRestDay ? 'Rest' : day.items.join('\n'),
                  style: TextStyle(
                    color: selected ? Colors.black87 : Colors.white60,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _weekdayLabel(int index) {
    return switch (index) {
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
      7 => 'Sun',
      _ => '',
    };
  }
}

class _SelectedWorkoutCard extends StatelessWidget {
  const _SelectedWorkoutCard({
    required this.day,
    required this.steps,
    required this.isToday,
    required this.onStart,
    required this.onStepSelected,
  });

  final RoutineDay day;
  final List<RoutineSessionStep> steps;
  final bool isToday;
  final VoidCallback? onStart;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday ? "Today's Exercises" : '${day.title} Exercises',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (day.isRestDay)
            const Text(
              'No exercises today.',
              style: TextStyle(color: Colors.white70),
            )
          else if (steps.isEmpty)
            const Text(
              'No matching exercise items were found for today.',
              style: TextStyle(color: Colors.white70),
            )
          else
            for (var i = 0; i < steps.length; i++)
              _WorkoutStepRow(
                index: i + 1,
                step: steps[i],
                onTap: () => onStepSelected(i),
              ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                isToday ? 'Start Today Session' : 'Start Selected Session',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutStepRow extends StatelessWidget {
  const _WorkoutStepRow({
    required this.index,
    required this.step,
    required this.onTap,
  });

  final int index;
  final RoutineSessionStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Set ${step.setNumber}/${step.totalSets} • ${step.effortLabel}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 52),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
