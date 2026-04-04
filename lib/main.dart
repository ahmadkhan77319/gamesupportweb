import 'package:flutter/material.dart';
import 'screens/customer_support_assistant.dart';
import 'screens/web_game_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Acres Tools',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainNavigationHome(),
    );
  }
}

class MainNavigationHome extends StatefulWidget {
  const MainNavigationHome({super.key});

  @override
  State<MainNavigationHome> createState() => _MainNavigationHomeState();
}

class _MainNavigationHomeState extends State<MainNavigationHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          [
            const WebGameScreen(),
            const CustomerSupportAssistant(),
          ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Web',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Support Assistant',
          ),
        ],
      ),
    );
  }
}
