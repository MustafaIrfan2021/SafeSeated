import 'package:material_ui/material_ui.dart';
import 'passenger_home_screen.dart';
import 'passenger_bookings_screen.dart';
import '../../../safety/presentation/screens/safety_screen.dart';
import '../../../profile/presentation/screens/passenger_profile_screen.dart';

class PassengerShellScreen extends StatefulWidget {
  final int initialTab;

  const PassengerShellScreen({super.key, this.initialTab = 0});

  @override
  State<PassengerShellScreen> createState() => _PassengerShellScreenState();
}

class _PassengerShellScreenState extends State<PassengerShellScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    PassengerHomeScreen(),
    PassengerBookingsScreen(),
    SafetyScreen(),
    PassengerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: _TabIcon(icon: Icons.home_outlined),
            activeIcon: _TabIcon(icon: Icons.home_rounded, selected: true),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(icon: Icons.calendar_today_outlined),
            activeIcon: _TabIcon(
              icon: Icons.calendar_today_rounded,
              selected: true,
            ),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(icon: Icons.shield_outlined),
            activeIcon: _TabIcon(icon: Icons.shield_rounded, selected: true),
            label: 'Safety & Help',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(icon: Icons.person_outline),
            activeIcon: _TabIcon(icon: Icons.person_rounded, selected: true),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _TabIcon({required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFF0EDFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: 20),
  );
}
