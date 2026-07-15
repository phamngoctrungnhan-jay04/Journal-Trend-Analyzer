import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'journals_screen.dart';
import 'keywords_screen.dart';
import 'profile_screen.dart';

// Bottom Nav Bar cấp app, nối 4 tab chính. Dùng IndexedStack để giữ state
// (kết quả search, vị trí scroll...) của từng tab khi chuyển qua lại.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    HomeScreen(),
    JournalsScreen(),
    KeywordsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.library_books_rounded),
            label: 'Journals',
          ),
          NavigationDestination(icon: Icon(Icons.label_rounded), label: 'Keywords'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
