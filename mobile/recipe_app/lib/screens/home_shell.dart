import 'package:flutter/material.dart';
import 'capture_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1; // Default to "New" (middle)
  final List<GlobalKey<NavigatorState>> _navKeys = [
    GlobalKey<NavigatorState>(), // Recipes
    GlobalKey<NavigatorState>(), // New
    GlobalKey<NavigatorState>(), // Profile
  ];

  Future<bool> _onWillPop() async {
    final currentNavigator = _navKeys[_index].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    return true;
  }

  void _onTap(int i) {
    if (i == _index) {
      // Pop to first route of the current tab
      final nav = _navKeys[i].currentState;
      nav?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            // Recipes tab
            Navigator(
              key: _navKeys[0],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const HistoryScreen(),
              ),
            ),
            // New tab
            Navigator(
              key: _navKeys[1],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const CaptureScreen(),
              ),
            ),
            // Profile tab
            Navigator(
              key: _navKeys[2],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: 'Recipes'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'New'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}


