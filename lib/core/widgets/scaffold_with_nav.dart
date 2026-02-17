import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  static const _tabs = ['/home', '/matches', '/series', '/players', '/profile'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => context.go(_tabs[index]),
          items: [
            _navItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
            _navItem(
              Icons.sports_cricket_rounded,
              Icons.sports_cricket_outlined,
              'Matches',
            ),
            _navItem(
              Icons.emoji_events_rounded,
              Icons.emoji_events_outlined,
              'Series',
            ),
            _navItem(Icons.people_rounded, Icons.people_outlined, 'Players'),
            _navItem(Icons.person_rounded, Icons.person_outlined, 'Profile'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
    IconData active,
    IconData inactive,
    String label,
  ) {
    return BottomNavigationBarItem(
      activeIcon: Icon(active),
      icon: Icon(inactive),
      label: label,
    );
  }
}
