import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lendahand/screens/auth/login_screen.dart';
import 'package:lendahand/screens/home/home_screen.dart';
import 'config/routes.dart';
import 'theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lend A Hand',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData) {
            return const HomeScreen(title: 'Home'); // Your home screen
          }
          return const LoginScreen();
        },
      ),
      routes: Routes.getRoutes(),
    );
  }
}
