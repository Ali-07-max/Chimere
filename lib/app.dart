import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/analytics_service.dart';
import 'theme/app_theme.dart';

class GamifiedProductivityApp extends StatelessWidget {
  const GamifiedProductivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: 'Gamified Productivity',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _Bootstrapper(),
        routes: {
          '/home': (context) => const HomeShell(),
          '/sign_in': (context) => const SignInScreen(),
          '/sign_up': (context) => const SignUpScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
        },
      ),
    );
  }
}

class _Bootstrapper extends StatefulWidget {
  const _Bootstrapper();

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final taskProvider = context.read<TaskProvider>();

    await authProvider.initialize();
    await settingsProvider.load();

    if (authProvider.isSignedIn && authProvider.user != null) {
      await taskProvider.initialize(authProvider.user!.id);
      await AnalyticsService.logSessionStart(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        return Consumer3<AuthProvider, SettingsProvider, TaskProvider>(
          builder: (context, authProvider, settingsProvider, taskProvider, _) {
            if (!authProvider.isSignedIn || authProvider.user == null) {
              return const SignInScreen();
            }

            if (!taskProvider.isInitialized ||
                taskProvider.userId != authProvider.user!.id) {
              Future.microtask(() async {
                await taskProvider.initialize(authProvider.user!.id);
              });
              return const SplashScreen();
            }

            if (!settingsProvider.settings.onboardingComplete) {
              return const OnboardingScreen();
            }

            return const HomeShell();
          },
        );
      },
    );
  }
}