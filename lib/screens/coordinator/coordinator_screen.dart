import 'package:flutter/material.dart';
import 'package:lendahand/screens/coordinator/coordinator_donate_screen.dart';
import '../settings/settings_screen.dart';
import '../tabs/updates_screen.dart';
import 'volunteer_requests_screen.dart';

class CoordinatorScreen extends StatefulWidget {
  const CoordinatorScreen({Key? key}) : super(key: key);

  @override
  State<CoordinatorScreen> createState() => _CoordinatorScreenState();
}

class _CoordinatorScreenState extends State<CoordinatorScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const CoordinatorHomeTab(),
    const UpdatesScreen(),
    const CoordinatorDonateScreen(),
    const VolunteerRequestsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(
          'Coordinator Dashboard',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 80,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onBackground,
          backgroundColor: Theme.of(context).colorScheme.background,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Updates',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism),
              label: 'Donate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_add),
              label: 'Volunteers',
            ),
          ],
        ),
      ),
    );
  }
}

// Add Coordinator Home Tab
class CoordinatorHomeTab extends StatelessWidget {
  const CoordinatorHomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Coordinator Home Tab'),
    );
  }
}
