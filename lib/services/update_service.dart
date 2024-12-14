import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getUpdates({String? filterByUser}) {
    if (filterByUser != null) {
      // Show all user's own updates regardless of expiry
      return _firestore
          .collection('updates')
          .where('authorId', isEqualTo: filterByUser)
          .snapshots();
    } else {
      // Show only approved updates
      return _firestore
          .collection('updates')
          .where('status', isEqualTo: 'approved')
          .snapshots();
    }
  }

  Future<void> createUpdate({
    required String title,
    required String description,
    required String type,
    required String location,
    required String severity,
    String status = 'pending',
    DateTime? expiryDate,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('updates').add({
        'title': title,
        'description': description,
        'type': type,
        'location': location,
        'severity': severity,
        'imageUrl': imageUrl,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
      });
    } catch (e) {
      throw Exception('Error creating update: $e');
    }
  }

  Future<void> updateStatus({
    required String updateId,
    required String status,
    String? coordinatorNote,
    DateTime? expiryDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('updates').doc(updateId).update({
        'status': status,
        'coordinatorId': user.uid,
        'coordinatorName': user.displayName,
        'coordinatorNote': coordinatorNote,
        'reviewedAt': FieldValue.serverTimestamp(),
        'expiryDate': expiryDate?.toUtc(),
      });
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }
}
