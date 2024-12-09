import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text('Settings',
            style: TextStyle(color: AppColors.secondaryYellow)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: AppColors.secondaryYellow,
                    ),
                    title: const Text('Edit Account'),
                    onTap: () {
                      // TODO: Implement edit account
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.secondaryYellow,
                    ),
                    title: const Text('Notification Settings'),
                    onTap: () {
                      // TODO: Implement notification settings
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.security_outlined,
                      color: AppColors.secondaryYellow,
                    ),
                    title: const Text('Privacy & Security'),
                    onTap: () {
                      // TODO: Implement privacy settings
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: AppColors.secondaryYellow,
                    ),
                    title: const Text('Logout'),
                    onTap: () async {
                      await _authService.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
