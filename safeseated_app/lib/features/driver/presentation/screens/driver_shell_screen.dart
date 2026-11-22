import 'package:material_ui/material_ui.dart';
import '../../../safety/presentation/screens/sos_dialog.dart';
import 'driver_dashboard_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_rides_screen.dart';
import 'driver_trips_screen.dart';
import 'driver_wallet_screen.dart';

class DriverShellScreen extends StatefulWidget {
  final int initialTab;

  const DriverShellScreen({super.key, this.initialTab = 0});

  @override
  State<DriverShellScreen> createState() => _DriverShellScreenState();
}

class _DriverShellScreenState extends State<DriverShellScreen> {
  static const _tabCount = 5;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, _tabCount - 1).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DriverDashboardScreen(),
          DriverTripsScreen(isActive: _currentIndex == 1),
          const DriverRidesScreen(),
          const DriverWalletScreen(),
          const DriverProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded),
        label: const Text('SOS'),
        onPressed: () => showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const SosDialog(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: _TabIcon(icon: Icons.home_outlined),
            activeIcon: _TabIcon(icon: Icons.home_rounded, selected: true),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(icon: Icons.people_outline),
            activeIcon: _TabIcon(icon: Icons.people_rounded, selected: true),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(icon: Icons.directions_car_outlined),
            activeIcon: _TabIcon(
              icon: Icons.directions_car_rounded,
              selected: true,
            ),
            label: 'Rides',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(icon: Icons.account_balance_wallet_outlined),
            activeIcon: _TabIcon(
              icon: Icons.account_balance_wallet_rounded,
              selected: true,
            ),
            label: 'Wallet',
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
