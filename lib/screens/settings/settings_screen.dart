import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/local_storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;

        Future<void> update({
          bool? notificationsEnabled,
          bool? analyticsEnabled,
          bool? competitiveMode,
        }) {
          return provider.updateSettings(
            settings.copyWith(
              notificationsEnabled: notificationsEnabled,
              analyticsEnabled: analyticsEnabled,
              competitiveMode: competitiveMode,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: settings.notificationsEnabled,
                      onChanged: (value) => update(notificationsEnabled: value),
                      title: const Text('Notifications'),
                      subtitle: const Text('Allow reminder and progress nudges.'),
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      value: settings.analyticsEnabled,
                      onChanged: (value) => update(analyticsEnabled: value),
                      title: const Text('Analytics'),
                      subtitle: const Text('Track task completion and engagement events locally.'),
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      value: settings.competitiveMode,
                      onChanged: (value) => update(competitiveMode: value),
                      title: const Text('Competitive mode'),
                      subtitle: const Text('Optional placeholder for future social features.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.manage_search_rounded),
                      title: const Text('View analytics count'),
                      subtitle: const Text('Quick check of locally tracked events'),
                      onTap: () {
                        AnalyticsService.getEvents().then((events) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Stored analytics events: ${events.length}')),
                            );
                          }
                        });
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: const Text('Reset tasks and achievements'),
                      onTap: () {
                        context.read<TaskProvider>().reset().then((_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task data reset.')),
                            );
                          }
                        });
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_outlined),
                      title: const Text('Reset entire app'),
                      onTap: () {
                        LocalStorageService.clearAll();
                        context.read<AuthProvider>().signOut();
                        context.read<SettingsProvider>().reset();
                        context.read<TaskProvider>().reset();
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out'),
                      onTap: () {
                        context.read<AuthProvider>().signOut();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
