import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ten_thousands_hours/services/shared_prefs_service.dart';

final storageProvider = Provider<SharedUtility>((ref) {
  final sharedPrefs = ref.watch(sharedPrefsProvider);
  return SharedUtility(sharedPreferences: sharedPrefs);
});

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});
