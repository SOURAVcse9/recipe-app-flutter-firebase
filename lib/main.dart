import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/preferences_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/review_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'providers/recently_viewed_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
        ChangeNotifierProvider(create: (_) => RecentlyViewedProvider()),
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

/// A wrapper that handles routing based on active Firebase Auth state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.loading && authProvider.currentUser == null) {
      return const Scaffold(body: LoadingView());
    }

    if (authProvider.isAuthenticated) {
      return const MainNavigation();
    }

    return const LoginScreen();
  }
}