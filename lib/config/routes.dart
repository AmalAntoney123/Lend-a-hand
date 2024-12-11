import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/coordinator/coordinator_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/volunteer/volunteer_screen.dart';

class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String admin = '/admin';
  static const String volunteer = '/volunteer';
  static const String settings = '/settings';
  static const String coordinator = '/coordinator';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) => const HomeScreen(title: 'Lend A Hand Home'),
      settings: (context) => SettingsScreen(),
      admin: (context) => AdminDashboard(),
      volunteer: (context) => const VolunteerScreen(),
      coordinator: (context) => const CoordinatorScreen(),
    };
  }
}
