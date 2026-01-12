import 'package:biomarcadores/screens/dashboard_screen.dart';
import 'package:biomarcadores/screens/measure_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;

  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(key: _dashboardKey),
      const MeasureScreen(),
      const Scaffold(body: Center(child: Text("Historial"))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const coralColor = Color(0xFFFF7043);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
           setState(() => _currentIndex = idx);
           if (idx == 0) {
              // Auto-refresh dashboard when returning home
              _dashboardKey.currentState?.loadBPM();
           }
        },
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: coralColor.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: coralColor),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart, color: coralColor),
            label: 'Medir',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: coralColor),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
