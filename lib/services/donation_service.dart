import 'package:cloud_firestore/cloud_firestore.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createDonation({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> acceptedItems,
    required bool acceptsMoney,
    required List<String> assignedVolunteers,
    String? status = 'active',
  }) async {
    try {
      await _firestore.collection('donations').add({
        'title': title,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'acceptedItems': acceptedItems,
        'acceptsMoney': acceptsMoney,
        'createdAt': Timestamp.now(),
        'status': status,
        'moneyDonations': [],
        'itemDonations': [],
        'assignedVolunteers': assignedVolunteers,
      });
    } catch (e) {
      throw Exception('Error creating donation: $e');
    }
  }

  Future<void> updateDonation({
    required String donationId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> acceptedItems,
    required bool acceptsMoney,
    required List<String> assignedVolunteers,
  }) async {
    try {
      await _firestore.collection('donations').doc(donationId).update({
        'title': title,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'acceptedItems': acceptedItems,
        'acceptsMoney': acceptsMoney,
        'assignedVolunteers': assignedVolunteers,
      });
    } catch (e) {
      throw Exception('Error updating donation: $e');
    }
  }

  Future<void> deleteDonation(String donationId) async {
    try {
      await _firestore.collection('donations').doc(donationId).delete();
    } catch (e) {
      throw Exception('Error deleting donation: $e');
    }
  }

  Stream<QuerySnapshot> getActiveDonations() {
    return _firestore
        .collection('donations')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  Stream<QuerySnapshot> getPastDonations() {
    return _firestore
        .collection('donations')
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getDonationById(String donationId) {
    return _firestore.collection('donations').doc(donationId).snapshots();
  }

  Stream<QuerySnapshot> getApprovedVolunteers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .where('isApproved', isEqualTo: true)
        .snapshots();
  }

  Future<void> addMoneyDonation({
    required String donationId,
    required double amount,
    required String donorName,
  }) async {
    try {
      await _firestore.collection('donations').doc(donationId).update({
        'moneyDonations': FieldValue.arrayUnion([
          {
            'amount': amount,
            'donor': donorName,
            'date': Timestamp.now(),
          }
        ]),
      });
    } catch (e) {
      throw Exception('Error adding money donation: $e');
    }
  }

  Future<void> addItemDonation({
    required String donationId,
    required String item,
    required String donorName,
  }) async {
    try {
      await _firestore.collection('donations').doc(donationId).update({
        'itemDonations': FieldValue.arrayUnion([
          {
            'item': item,
            'donor': donorName,
            'date': Timestamp.now(),
          }
        ]),
      });
    } catch (e) {
      throw Exception('Error adding item donation: $e');
    }
  }

  Future<void> updateDonationStatus({
    required String donationId,
    required String status,
  }) async {
    try {
      await _firestore.collection('donations').doc(donationId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Error updating donation status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVolunteersByIds(
      List<String> volunteerIds) async {
    try {
      final volunteers = await Future.wait(
        volunteerIds.map((id) => _firestore.collection('users').doc(id).get()),
      );

      return volunteers
          .where((doc) => doc.exists)
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Error fetching volunteers: $e');
    }
  }

  Stream<QuerySnapshot> getVolunteerAssignedDonations(String volunteerId) {
    return _firestore
        .collection('donations')
        .where('assignedVolunteers', arrayContains: volunteerId)
        .snapshots();
  }
}
