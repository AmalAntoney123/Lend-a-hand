import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerRequestsPanel extends StatelessWidget {
  const VolunteerRequestsPanel({Key? key}) : super(key: key);

  void _showUserDetails(BuildContext context, Map<String, dynamic> userData) {
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
            _detailRow('Full Name', userData['fullName'] ?? 'Not provided'),
            _detailRow('Email', userData['email'] ?? 'Not provided'),
            _detailRow('Phone', userData['phoneNumber'] ?? 'Not provided'),
            _detailRow('Age', userData['age']?.toString() ?? 'Not provided'),
            _detailRow('Gender', userData['sex'] ?? 'Not provided'),
            _detailRow('Blood Group', userData['bloodGroup'] ?? 'Not provided'),
            _detailRow('Address', userData['address'] ?? 'Not provided'),
            _detailRow('Skills', userData['skills'] ?? 'Not provided'),
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No pending volunteer requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final userData = requests[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(userData['fullName'] ?? 'No name'),
                subtitle: Text(userData['phoneNumber'] ?? 'No phone number'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showUserDetails(context, userData),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveUser(requests[index].id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectUser(requests[index].id),
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

  Future<void> _approveUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isApproved': true,
    });
  }

  Future<void> _rejectUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
  }
}
