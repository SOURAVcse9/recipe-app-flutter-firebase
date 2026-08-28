import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/preferences_provider.dart';
import 'providers/recipe_provider.dart';
import 'screens/main_navigation.dart';
import 'utils/app_theme.dart';
import 'widgets/state_views.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: const RecipeApp(),
    ),
  );
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.watch<PreferencesProvider>().current.activeThemeMode;

    return MaterialApp(
      title: 'Recipe App',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: themeMode,
      home: const AuthWrapper(),
    );
  }
}

/// A loading wrapper that blocks normal application entry until anonymous
/// Firebase authentication is successfully completed.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    if (provider.authLoading) {
      return const Scaffold(body: LoadingView());
    }

    if (provider.authError != null) {
      return Scaffold(
        body: ErrorView(
          message: provider.authError!,
          onRetry: () => provider.retryAuthentication(),
        ),
      );
    }

    return const MainNavigation();
  }
}