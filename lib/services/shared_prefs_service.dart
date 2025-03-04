import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedUtility {
  SharedUtility({
    required this.sharedPreferences,
  });

  final SharedPreferences sharedPreferences;

  String? getSavedAppState() {
    return sharedPreferences.getString('app_state');
  }

  void updateAppState(String data) {
    sharedPreferences.setString('app_state', data);
    debugPrint('STORAGE UPDATED');
  }

  void saveTimeData(String data) {
    sharedPreferences.setString('timeData', data);
  }

  String? getTimeData() {
    return sharedPreferences.getString('timeData');
  }

  final recordKey = 'record';
  final eventLstKey = 'eventLstKey';
  final timeData = 'timeData';
}
