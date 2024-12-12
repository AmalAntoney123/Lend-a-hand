import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lendahand/screens/auth/login_screen.dart';
import 'package:lendahand/screens/home/home_screen.dart';
import 'config/routes.dart';
import 'screens/coordinator/coordinator_screen.dart';
import 'screens/volunteer/volunteer_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await NotificationService.requestPermission();
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
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final role = userData['role'] as String;
                  final isApproved = userData['isApproved'] as bool;

                  if (role != 'commoner' && !isApproved) {
                    FirebaseAuth.instance.signOut();
                    return const LoginScreen();
                  }

                  switch (role) {
                    case 'admin':
                      return AdminDashboard();
                    case 'coordinator':
                      if (isApproved) return CoordinatorScreen();
                      break;
                    case 'volunteer':
                      if (isApproved) return VolunteerScreen();
                      break;
                    default:
                      return const HomeScreen(title: 'Home');
                  }
                }

                return const LoginScreen();
              },
            );
          }
          return const LoginScreen();
        },
      ),
      routes: Routes.getRoutes(),
    );
  }
}
