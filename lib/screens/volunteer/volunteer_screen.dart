import 'package:flutter/material.dart';
import 'package:lendahand/screens/volunteer/volunteer_donate_screen.dart';
import '../settings/settings_screen.dart';
import '../tabs/updates_screen.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const VolunteerHomeTab(),
    const UpdatesScreen(),
    const VolunteerDonateScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(
          'Volunteer Dashboard',
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
          ],
        ),
      ),
    );
  }
}

// Add Volunteer Home Tab
class VolunteerHomeTab extends StatelessWidget {
  const VolunteerHomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Volunteer Home Tab'),
    );
  }
}
