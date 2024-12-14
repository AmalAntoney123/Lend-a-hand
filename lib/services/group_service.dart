import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/volunteer_call.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new group
  Future<String> createGroup(
      String name, List<String> volunteerIds, String coordinatorId) async {
    final docRef = _firestore.collection('groups').doc();
    final group = Group(
      id: docRef.id,
      name: name,
      coordinatorId: coordinatorId,
      volunteerIds: volunteerIds,
      createdAt: DateTime.now(),
    );

    await docRef.set(group.toMap());
    return docRef.id;
  }

  // Create a volunteer call
  Future<String> createVolunteerCall(String groupId, String title,
      String description, DateTime eventDate) async {
    final docRef = _firestore.collection('volunteer_calls').doc();
    final call = VolunteerCall(
      id: docRef.id,
      groupId: groupId,
      title: title,
      description: description,
      eventDate: eventDate,
      createdAt: DateTime.now(),
      responses: {},
    );

    await docRef.set(call.toMap());
    return docRef.id;
  }

  // Respond to a volunteer call
  Future<void> respondToCall(
      String callId, String volunteerId, bool accepted) async {
    await _firestore.collection('volunteer_calls').doc(callId).update({
      'responses.$volunteerId': accepted,
    });
  }

  // Get all volunteers who accepted a call
  Stream<List<String>> getAcceptedVolunteers(String callId) {
    return _firestore
        .collection('volunteer_calls')
        .doc(callId)
        .snapshots()
        .map((doc) {
      final call = VolunteerCall.fromMap(doc.data()!);
      return call.responses.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
    });
  }
}
