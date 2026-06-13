import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _dayOverridePrefsKey = 'routine_day_overrides_v1';
  static const _routineLevelPrefsKey = 'routine_level_v1';

  final RoutineService _routineService = RoutineService();
  late Future<RoutinePlan> _planFuture;
  Map<int, int> _dayOverrides = const {};
  int? _selectedDayIndex;
  RoutineLevel _selectedLevel = RoutineLevel.beginner;

  @override
  void initState() {
    super.initState();
    _planFuture = _routineService.loadPlan(level: _selectedLevel);
    _loadDayOverrides();
    _loadRoutineLevel();
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

  Future<void> _loadDayOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOverrides =
        prefs.getStringList(_dayOverridePrefsKey) ?? const <String>[];
    final overrides = <int, int>{};

    for (final override in savedOverrides) {
      final parts = override.split(':');
      if (parts.length != 2) continue;

      final dayIndex = int.tryParse(parts[0]);
      final sourceDayIndex = int.tryParse(parts[1]);
      if (dayIndex == null || sourceDayIndex == null) continue;
      if (dayIndex == sourceDayIndex) continue;

      overrides[dayIndex] = sourceDayIndex;
    }

    if (!mounted) return;
    setState(() {
      _dayOverrides = overrides;
    });
  }

  Future<void> _loadRoutineLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final level = RoutineLevel.fromName(
      prefs.getString(_routineLevelPrefsKey) ?? '',
    );

    if (!mounted || level == _selectedLevel) return;
    setState(() {
      _selectedLevel = level;
      _selectedDayIndex = null;
      _planFuture = _routineService.loadPlan(level: level);
    });
  }

  Future<void> _setRoutineLevel(RoutineLevel level) async {
    if (level == _selectedLevel) return;

    setState(() {
      _selectedLevel = level;
      _selectedDayIndex = null;
      _planFuture = _routineService.loadPlan(level: level);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routineLevelPrefsKey, level.name);
  }

  Future<void> _saveDayOverrides(Map<int, int> overrides) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dayOverridePrefsKey,
      overrides.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .toList(growable: false),
    );
  }

  RoutineDay _dayForIndex(RoutinePlan plan, int dayIndex) {
    return plan.days.firstWhere(
      (day) => day.index == dayIndex,
      orElse: () => plan.today,
    );
  }

  RoutineDay _workoutForSlot(RoutinePlan plan, RoutineDay daySlot) {
    return _dayForIndex(plan, _dayOverrides[daySlot.index] ?? daySlot.index);
  }

  bool _hasCustomPlan(RoutineDay daySlot) {
    final override = _dayOverrides[daySlot.index];
    return override != null && override != daySlot.index;
  }

  Future<void> _setWorkoutForSlot({
    required RoutineDay daySlot,
    required RoutineDay workoutDay,
  }) async {
    final overrides = Map<int, int>.from(_dayOverrides);
    if (daySlot.index == workoutDay.index) {
      overrides.remove(daySlot.index);
    } else {
      overrides[daySlot.index] = workoutDay.index;
    }

    setState(() {
      _dayOverrides = overrides;
    });
    await _saveDayOverrides(overrides);
  }

  Future<void> _swapWorkoutSlots({
    required RoutinePlan plan,
    required RoutineDay firstSlot,
    required RoutineDay secondSlot,
  }) async {
    if (firstSlot.index == secondSlot.index) return;

    final firstWorkout = _workoutForSlot(plan, firstSlot);
    final secondWorkout = _workoutForSlot(plan, secondSlot);
    final overrides = Map<int, int>.from(_dayOverrides);

    if (firstSlot.index == secondWorkout.index) {
      overrides.remove(firstSlot.index);
    } else {
      overrides[firstSlot.index] = secondWorkout.index;
    }

    if (secondSlot.index == firstWorkout.index) {
      overrides.remove(secondSlot.index);
    } else {
      overrides[secondSlot.index] = firstWorkout.index;
    }

    setState(() {
      _dayOverrides = overrides;
    });
    await _saveDayOverrides(overrides);
  }

  Future<void> _restoreDefaults() async {
    if (_dayOverrides.isEmpty) return;

    setState(() {
      _dayOverrides = const {};
    });
    await _saveDayOverrides(const {});
  }

  Future<void> _changeWorkoutForSlot({
    required RoutinePlan plan,
    required RoutineDay daySlot,
  }) async {
    final currentWorkout = _workoutForSlot(plan, daySlot);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171A1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Swap ${_weekdayLabel(daySlot.index)} workout',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Restore default',
                      color: Colors.white70,
                      onPressed: _hasCustomPlan(daySlot)
                          ? () async {
                              await _setWorkoutForSlot(
                                daySlot: daySlot,
                                workoutDay: daySlot,
                              );
                              if (context.mounted) Navigator.pop(context);
                            }
                          : null,
                      icon: const Icon(Icons.restore),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: plan.days.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final workoutDay = plan.days[index];
                      final selected = workoutDay.index == daySlot.index;
                      final slotWorkout = _workoutForSlot(plan, workoutDay);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected ? Colors.orange : Colors.white38,
                        ),
                        title: Text(
                          '${_weekdayLabel(workoutDay.index)}  ${slotWorkout.title}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          workoutDay.index == daySlot.index
                              ? 'Current ${currentWorkout.title}'
                              : slotWorkout.isRestDay
                              ? 'Rest'
                              : slotWorkout.items.join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () async {
                          await _swapWorkoutSlots(
                            plan: plan,
                            firstSlot: daySlot,
                            secondSlot: workoutDay,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

          final todaySlot = plan.today;
          final todayWorkout = _workoutForSlot(plan, todaySlot);
          final selectedDaySlot = plan.days.firstWhere(
            (day) => day.index == _selectedDayIndex,
            orElse: () => todaySlot,
          );
          final selectedWorkoutDay = _workoutForSlot(plan, selectedDaySlot);
          final steps = _routineService.buildSessionSteps(
            selectedWorkoutDay,
            plan.exerciseItems,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SelectedDayHeader(
                daySlot: selectedDaySlot,
                workoutDay: selectedWorkoutDay,
                level: _selectedLevel,
                isToday: selectedDaySlot.index == todaySlot.index,
                hasCustomPlan: _hasCustomPlan(selectedDaySlot),
              ),
              const SizedBox(height: 16),
              _LevelSelector(
                selectedLevel: _selectedLevel,
                onSelected: _setRoutineLevel,
              ),
              const SizedBox(height: 16),
              _WeekTable(
                plan: plan,
                selectedDaySlot: selectedDaySlot,
                todaySlot: todaySlot,
                dayOverrides: _dayOverrides,
                workoutForSlot: (daySlot) => _workoutForSlot(plan, daySlot),
                onSelected: (day) {
                  setState(() {
                    _selectedDayIndex = day.index;
                  });
                },
                onChangeWorkout: (daySlot) =>
                    _changeWorkoutForSlot(plan: plan, daySlot: daySlot),
                onRestoreDefaults: _restoreDefaults,
              ),
              const SizedBox(height: 18),
              _SelectedWorkoutCard(
                daySlot: selectedDaySlot,
                workoutDay: selectedWorkoutDay,
                steps: steps,
                isToday: selectedDaySlot.index == todaySlot.index,
                isTodayWorkout: selectedWorkoutDay.index == todayWorkout.index,
                hasCustomPlan: _hasCustomPlan(selectedDaySlot),
                onStart: selectedWorkoutDay.isRestDay || steps.isEmpty
                    ? null
                    : () => _openSession(selectedWorkoutDay, steps),
                onStepSelected: (index) => _openSession(
                  selectedWorkoutDay,
                  steps,
                  initialStepIndex: index,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({
    required this.daySlot,
    required this.workoutDay,
    required this.level,
    required this.isToday,
    required this.hasCustomPlan,
  });

  final RoutineDay daySlot;
  final RoutineDay workoutDay;
  final RoutineLevel level;
  final bool isToday;
  final bool hasCustomPlan;

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
            isToday
                ? 'Today • ${level.label}'
                : '${_weekdayLabel(daySlot.index)} • ${level.label}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            workoutDay.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (hasCustomPlan) ...[
            Text(
              'Using ${_weekdayLabel(workoutDay.index)} workout',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            workoutDay.isRestDay
                ? 'Rest and recover.'
                : '${workoutDay.sets} sets • ${workoutDay.rep} • Rest ${workoutDay.restSeconds}s',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({required this.selectedLevel, required this.onSelected});

  final RoutineLevel selectedLevel;
  final ValueChanged<RoutineLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final level in RoutineLevel.values) ...[
          Expanded(
            child: _LevelButton(
              level: level,
              selected: level == selectedLevel,
              onTap: () => onSelected(level),
            ),
          ),
          if (level != RoutineLevel.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final RoutineLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.orange : const Color(0xFF1B1F22),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Colors.orangeAccent : Colors.white12,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              level.label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekTable extends StatelessWidget {
  const _WeekTable({
    required this.plan,
    required this.selectedDaySlot,
    required this.todaySlot,
    required this.dayOverrides,
    required this.workoutForSlot,
    required this.onSelected,
    required this.onChangeWorkout,
    required this.onRestoreDefaults,
  });

  final RoutinePlan plan;
  final RoutineDay selectedDaySlot;
  final RoutineDay todaySlot;
  final Map<int, int> dayOverrides;
  final RoutineDay Function(RoutineDay daySlot) workoutForSlot;
  final ValueChanged<RoutineDay> onSelected;
  final ValueChanged<RoutineDay> onChangeWorkout;
  final VoidCallback onRestoreDefaults;

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
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Week Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Restore defaults',
                  color: dayOverrides.isEmpty ? Colors.white24 : Colors.white70,
                  onPressed: dayOverrides.isEmpty ? null : onRestoreDefaults,
                  icon: const Icon(Icons.restore),
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
                  for (final day in plan.days)
                    _DayColumn(
                      daySlot: day,
                      workoutDay: workoutForSlot(day),
                      selected: day.index == selectedDaySlot.index,
                      isToday: day.index == todaySlot.index,
                      hasCustomPlan: dayOverrides[day.index] != null,
                      onTap: () => onSelected(day),
                      onChangeWorkout: () => onChangeWorkout(day),
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
    required this.daySlot,
    required this.workoutDay,
    required this.selected,
    required this.isToday,
    required this.hasCustomPlan,
    required this.onTap,
    required this.onChangeWorkout,
  });

  final RoutineDay daySlot;
  final RoutineDay workoutDay;
  final bool selected;
  final bool isToday;
  final bool hasCustomPlan;
  final VoidCallback onTap;
  final VoidCallback onChangeWorkout;

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _weekdayLabel(daySlot.index),
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Change workout',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 30,
                        height: 30,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onChangeWorkout,
                      icon: Icon(
                        hasCustomPlan ? Icons.swap_horiz : Icons.edit_calendar,
                        size: 18,
                        color: selected ? Colors.black : Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isToday) ...[
                  Text(
                    'Today',
                    style: TextStyle(
                      color: selected ? Colors.black87 : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  workoutDay.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (hasCustomPlan) ...[
                  const SizedBox(height: 6),
                  Text(
                    'From ${_weekdayLabel(workoutDay.index)}',
                    style: TextStyle(
                      color: selected ? Colors.black87 : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  workoutDay.isRestDay ? 'Rest' : workoutDay.items.join('\n'),
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
}

class _SelectedWorkoutCard extends StatelessWidget {
  const _SelectedWorkoutCard({
    required this.daySlot,
    required this.workoutDay,
    required this.steps,
    required this.isToday,
    required this.isTodayWorkout,
    required this.hasCustomPlan,
    required this.onStart,
    required this.onStepSelected,
  });

  final RoutineDay daySlot;
  final RoutineDay workoutDay;
  final List<RoutineSessionStep> steps;
  final bool isToday;
  final bool isTodayWorkout;
  final bool hasCustomPlan;
  final VoidCallback? onStart;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    final totalTimeLabel = _totalWorkoutTimeLabel(steps);

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
            isToday
                ? "Today's Exercises"
                : '${_weekdayLabel(daySlot.index)} Exercises',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (hasCustomPlan || !isTodayWorkout) ...[
            const SizedBox(height: 6),
            Text(
              _workoutSubtitle(workoutDay.title, totalTimeLabel),
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ] else if (!workoutDay.isRestDay && steps.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Workout: ${workoutDay.title} • $totalTimeLabel',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          if (workoutDay.isRestDay)
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

  String _workoutSubtitle(String title, String totalTimeLabel) {
    if (workoutDay.isRestDay || steps.isEmpty) return 'Workout: $title';
    return 'Workout: $title • $totalTimeLabel';
  }

  String _totalWorkoutTimeLabel(List<RoutineSessionStep> steps) {
    final totalSeconds = steps.fold<int>(0, (total, step) {
      final exerciseSeconds = step.isTimed ? step.durationSeconds : 0;
      return total + exerciseSeconds + step.restSeconds;
    });
    final minutes = (totalSeconds / 60).ceil();
    return '$minutes min';
  }
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
