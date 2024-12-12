import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'panels/volunteer_requests_panel.dart';
import 'panels/coordinator_approvals_panel.dart';
import 'panels/user_management_panel.dart';
import 'panels/reports_panel.dart';
import 'panels/settings_panel.dart';
import 'panels/contact_requests_panel.dart';
import '../../theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final List<String> _titles = [
    'Volunteer Requests',
    'Coordinator Approvals',
    'User Management',
    'Contact Requests',
  ];

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const VolunteerRequestsPanel();
      case 1:
        return const CoordinatorApprovalsPanel();
      case 2:
        return const UserManagementPanel();
      case 3:
        return const ReportsPanel();
      case 4:
        return const ContactRequestsPanel();
      case 5:
        return const SettingsPanel();
      default:
        return const VolunteerRequestsPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 100),
                  ListTile(
                    selected: _selectedIndex == 0,
                    selectedTileColor: AppColors.primaryYellow.withOpacity(0.1),
                    selectedColor: AppColors.primaryYellow,
                    leading: Icon(
                      Icons.person_add,
                      color: _selectedIndex == 0
                          ? AppColors.primaryYellow
                          : AppColors.secondaryYellow,
                    ),
                    title: const Text('Volunteer Requests'),
                    onTap: () {
                      setState(() => _selectedIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    selected: _selectedIndex == 1,
                    selectedTileColor: AppColors.primaryYellow.withOpacity(0.1),
                    selectedColor: AppColors.primaryYellow,
                    leading: Icon(
                      Icons.admin_panel_settings,
                      color: _selectedIndex == 1
                          ? AppColors.primaryYellow
                          : AppColors.secondaryYellow,
                    ),
                    title: const Text('Coordinator Approvals'),
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    selected: _selectedIndex == 2,
                    selectedTileColor: AppColors.primaryYellow.withOpacity(0.1),
                    selectedColor: AppColors.primaryYellow,
                    leading: Icon(
                      Icons.people,
                      color: _selectedIndex == 2
                          ? AppColors.primaryYellow
                          : AppColors.secondaryYellow,
                    ),
                    title: const Text('User Management'),
                    onTap: () {
                      setState(() => _selectedIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    selected: _selectedIndex == 4,
                    selectedTileColor: AppColors.primaryYellow.withOpacity(0.1),
                    selectedColor: AppColors.primaryYellow,
                    leading: Icon(
                      Icons.contact_support,
                      color: _selectedIndex == 4
                          ? AppColors.primaryYellow
                          : AppColors.secondaryYellow,
                    ),
                    title: const Text('Contact Requests'),
                    onTap: () {
                      setState(() => _selectedIndex = 4);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.secondaryYellow.withOpacity(0.3)),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: AppColors.secondaryYellow,
              ),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: _getSelectedScreen(),
    );
  }
}
