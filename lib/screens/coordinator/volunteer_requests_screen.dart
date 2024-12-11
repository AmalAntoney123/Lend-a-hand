import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerRequestsScreen extends StatelessWidget {
  const VolunteerRequestsScreen({Key? key}) : super(key: key);

  void _showVolunteerDetails(
      BuildContext context, Map<String, dynamic> volunteerData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(
                'Full Name', volunteerData['fullName'] ?? 'Not provided'),
            _detailRow('Email', volunteerData['email'] ?? 'Not provided'),
            _detailRow('Phone', volunteerData['phoneNumber'] ?? 'Not provided'),
            _detailRow('Age', volunteerData['age']?.toString() ?? 'Not provided'),
            _detailRow('Gender', volunteerData['sex'] ?? 'Not provided'),
            _detailRow('Blood Group', volunteerData['bloodGroup'] ?? 'Not provided'),
            _detailRow('Address', volunteerData['address'] ?? 'Not provided'),
            _detailRow('Skills', volunteerData['skills'] ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('isApproved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error fetching volunteers: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        print('Number of requests found: ${requests.length}');
        print('Request data: ${requests.map((doc) => doc.data()).toList()}');

        if (requests.isEmpty) {
          return const Center(child: Text('No pending volunteer requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final volunteerData =
                requests[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(volunteerData['fullName'] ?? 'No name'),
                subtitle:
                    Text(volunteerData['phoneNumber'] ?? 'No phone number'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () =>
                          _showVolunteerDetails(context, volunteerData),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveVolunteer(requests[index].id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectVolunteer(requests[index].id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveVolunteer(String volunteerId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(volunteerId)
        .update({
      'isApproved': true,
    });
  }

  Future<void> _rejectVolunteer(String volunteerId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(volunteerId)
        .delete();
  }
}
