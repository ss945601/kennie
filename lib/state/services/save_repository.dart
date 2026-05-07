import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';

class SaveRepository {
  static const _saveKey = 'kennie.save.primary';

  Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  Future<void> save(GameSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(snapshot.toJson()));
  }

  Future<GameSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return GameSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
