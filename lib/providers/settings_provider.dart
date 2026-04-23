import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/analytics_service.dart';
import '../services/local_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> load() async {
    final data = await LocalStorageService.getMap(LocalStorageService.settingsKey);
    if (data != null && data.isNotEmpty) {
      _settings = AppSettings.fromMap(data);
      notifyListeners();
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await LocalStorageService.saveMap(LocalStorageService.settingsKey, settings.toMap());
    await AnalyticsService.logEvent('settings_updated');
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required List<String> goals,
    required bool consentGiven,
  }) async {
    _settings = _settings.copyWith(
      onboardingComplete: true,
      focusGoals: goals,
      consentGiven: consentGiven,
      analyticsEnabled: consentGiven,
    );
    await LocalStorageService.saveMap(LocalStorageService.settingsKey, _settings.toMap());
    await AnalyticsService.logEvent('onboarding_completed', payload: {'goals': goals});
    notifyListeners();
  }

  Future<void> reset() async {
    _settings = const AppSettings();
    await LocalStorageService.saveMap(LocalStorageService.settingsKey, _settings.toMap());
    notifyListeners();
  }
}
