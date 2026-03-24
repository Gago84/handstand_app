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

    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(key, list);
    }
  }

  static Future<bool> isDone(String id) async {
    final list = await getCompleted();
    return list.contains(id);
  }
}