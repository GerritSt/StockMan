import 'package:flutter/material.dart';

class NavigationBarStockman extends StatelessWidget {
  const NavigationBarStockman(
      this.currentIndex, this.onTap,
      {super.key});

  final int currentIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home), label: 'My herd'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Activities'),
          NavigationDestination(
              icon: Icon(Icons.list_alt), label: 'Change log'),
          NavigationDestination(
              icon: Icon(Icons.query_stats), label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
      );
  }
}
