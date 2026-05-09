// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/maintenance/domain/usecases/maintenance_usecases.dart';
import 'features/startup/presentation/cubits/startup_cubit.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _attachErrorHandlers();
  runApp(
    await _initApp(),
  );
}

/// Ensures framework errors are reported. In debug we print; in release
/// you can forward to a crash reporting service.
void _attachErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    // In release, optionally send details.exception to crash reporting.
  };
}

/// Initializes dependencies and returns the root widget. On failure in
/// production we show an error screen instead of crashing.
Future<Widget> _initApp() async {
  try {
    await initDependencies();
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool(DrivometryPrefs.hasSeenOnboarding) ?? false;
    return DrivometryApp(hasSeenOnboarding: hasSeenOnboarding);
  } catch (e, stack) {
    if (kDebugMode) {
      // In debug, print so developers see the cause.
      debugPrint('initDependencies failed: $e');
      debugPrintStack(stackTrace: stack);
    }
    return _InitErrorScreen(error: e.toString());
  }
}

/// Shown when dependency initialization fails (e.g. DB or notifications).
class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not start the app',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode ? error : 'Please try again or reinstall the app.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DrivometryApp extends StatelessWidget {
  const DrivometryApp({required this.hasSeenOnboarding, super.key});

  final bool hasSeenOnboarding;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StartupCubit>()..load(),
      child: BlocListener<StartupCubit, StartupState>(
        listenWhen: (previous, current) => current is StartupReady,
        listener: (context, state) => sl<RunMaintenanceReminderChecks>()(),
        child: BlocBuilder<StartupCubit, StartupState>(
          builder: (context, startupState) {
          if (startupState is! StartupReady) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final initialPath =
              hasSeenOnboarding ? startupState.initialPath : '/onboarding';
          // Create router once so theme changes don't recreate it and reset navigation.
          final router = AppRouter.createRouter(initialLocation: initialPath);
          return BlocProvider(
            create: (_) => ThemeCubit()..loadTheme(),
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return MaterialApp.router(
                  title: 'Drivometry',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  routerConfig: router,
                );
              },
            ),
          );
          },
        ),
      ),
    );
  }
}

class DrivometryPrefs {
  static const hasSeenOnboarding = 'has_seen_onboarding';
}
