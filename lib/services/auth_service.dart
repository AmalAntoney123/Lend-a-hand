import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<(UserCredential?, String?)> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Check if user is disabled
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _auth.signOut();
          return (null, 'User data not found');
        }

        // Update display name if not set
        if (userCredential.user!.displayName == null ||
            userCredential.user!.displayName!.isEmpty) {
          final fullName = userDoc.data()?['fullName'];
          if (fullName != null) {
            await userCredential.user!.updateDisplayName(fullName);
          }
        }

        final isDisabled = userDoc.data()?['isDisabled'] ?? false;
        if (isDisabled) {
          await _auth.signOut();
          return (
            null,
            'Your account has been disabled. Please contact admin for support.'
          );
        }

        final isApproved = userDoc.data()?['isApproved'] ?? false;
        final role = userDoc.data()?['role'] ?? '';

        if (!isApproved && role != 'commoner') {
          await _auth.signOut();
          return (null, 'Your account is pending approval');
        }

        return (userCredential, null);
      }
      return (null, 'An error occurred');
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';
      }
      return (null, message);
    }
  }

  // Register with email and password
  Future<(UserCredential?, String?)> registerWithEmailAndPassword(
    String email,
    String password,
    String role, {
    required String fullName,
    required String address,
    required int age,
    required String sex,
    required String bloodGroup,
    required String phoneNumber,
    required String skills,
    File? certificateFile,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create local directory to store certificates if it doesn't exist
        String? certificatePath;
        if (certificateFile != null) {
          // Get the file extension with the dot
          final fileExtension = path.extension(certificateFile.path);

          // Create filename with proper extension
          final fileName =
              '${userCredential.user!.uid}_${DateTime.now().millisecondsSinceEpoch}${fileExtension.isEmpty ? '.jpg' : fileExtension}';

          final appDir = await getApplicationDocumentsDirectory();
          final certificatesDir = Directory('${appDir.path}/certificates');
          if (!await certificatesDir.exists()) {
            await certificatesDir.create(recursive: true);
          }

          final localFile = File('${certificatesDir.path}/$fileName');
          await certificateFile.copy(localFile.path);
          certificatePath = localFile.path;
        }

        // Create user document in Firestore with additional fields
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'role': role.toLowerCase(),
          'isApproved': role.toLowerCase() == 'commoner',
          'createdAt': FieldValue.serverTimestamp(),
          'fullName': fullName,
          'address': address,
          'age': age,
          'sex': sex,
          'bloodGroup': bloodGroup,
          'phoneNumber': phoneNumber,
          'skills': skills,
          'certificatePath': certificatePath,
        });

        await _auth.signOut();
      }

      return (userCredential, null);
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'email-already-in-use') {
        message = 'Email is already registered';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }
      return (null, message);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found with this email';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address';
      }
      return 'An error occurred. Please try again later.';
    }
  }

  Future<(UserCredential?, String?)> signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return (null, 'Google sign-in aborted');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        // Update display name if needed
        if (userCredential.user!.displayName == null ||
            userCredential.user!.displayName!.isEmpty) {
          final fullName = userDoc.data()?['fullName'];
          if (fullName != null) {
            await userCredential.user!.updateDisplayName(fullName);
          }
        }
      }

      return (userCredential, null);
    } on FirebaseAuthException catch (e) {
      return (null, 'Error signing in with Google: ${e.message}');
    }
  }
}
