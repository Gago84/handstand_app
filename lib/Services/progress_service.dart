import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String key = "completed_exercises";

  static Future<List<String>> getCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  static Future<void> markDone(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    print("🔥 BEFORE SAVE: $list");

    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(key, list);
    }

    print("🔥 AFTER SAVE: $list");
  }

  static Future<bool> isDone(String id) async {
    final list = await getCompleted();
    return list.contains(id);
  }
  static const String warmupTimeKey = "warmup_time";

  static Future<void> saveWarmupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(warmupTimeKey, now);
  }
  static Future<bool> isWarmupValid() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(warmupTimeKey);

    if (saved == null) return false;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(saved);
    final now = DateTime.now();

    final diff = now.difference(savedTime);

    return diff.inSeconds < 10; // 🔥 10 second in test, 3h in production
  }
  
  // 🔥 SAVE FEEDBACK COUNT
  static Future<void> saveFeedback(int index, bool isGood) async {
    final prefs = await SharedPreferences.getInstance();

    final goodKey = "step_${index}_good";
    final badKey = "step_${index}_bad";

    if (isGood) {
      final current = prefs.getInt(goodKey) ?? 0;
      await prefs.setInt(goodKey, current + 1);
    } else {
      final current = prefs.getInt(badKey) ?? 0;
      await prefs.setInt(badKey, current + 1);
    }
  }

  // 🔥 GET FEEDBACK
  static Future<Map<String, int>> getFeedback(int index) async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "good": prefs.getInt("step_${index}_good") ?? 0,
      "bad": prefs.getInt("step_${index}_bad") ?? 0,
    };
  }
}