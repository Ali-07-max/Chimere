class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.analyticsEnabled = true,
    this.competitiveMode = false,
    this.consentGiven = false,
    this.onboardingComplete = false,
    this.focusGoals = const [],
  });

  final bool notificationsEnabled;
  final bool analyticsEnabled;
  final bool competitiveMode;
  final bool consentGiven;
  final bool onboardingComplete;
  final List<String> focusGoals;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? analyticsEnabled,
    bool? competitiveMode,
    bool? consentGiven,
    bool? onboardingComplete,
    List<String>? focusGoals,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      competitiveMode: competitiveMode ?? this.competitiveMode,
      consentGiven: consentGiven ?? this.consentGiven,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      focusGoals: focusGoals ?? this.focusGoals,
    );
  }

  Map<String, dynamic> toMap() => {
        'notificationsEnabled': notificationsEnabled,
        'analyticsEnabled': analyticsEnabled,
        'competitiveMode': competitiveMode,
        'consentGiven': consentGiven,
        'onboardingComplete': onboardingComplete,
        'focusGoals': focusGoals,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      analyticsEnabled: map['analyticsEnabled'] as bool? ?? true,
      competitiveMode: map['competitiveMode'] as bool? ?? false,
      consentGiven: map['consentGiven'] as bool? ?? false,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      focusGoals: List<String>.from(map['focusGoals'] as List? ?? const []),
    );
  }
}
