import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'favorites_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Preserves each tab's scroll/state using an IndexedStack instead of
/// rebuilding screens from scratch every time the user switches tabs.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home_2),
            activeIcon: Icon(Iconsax.home_25),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.heart),
            activeIcon: Icon(Iconsax.heart5),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.user),
            activeIcon: Icon(Iconsax.profile_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
