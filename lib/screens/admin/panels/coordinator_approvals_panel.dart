import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class CoordinatorApprovalsPanel extends StatelessWidget {
  const CoordinatorApprovalsPanel({Key? key}) : super(key: key);

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
            if (userData['certificatePath'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openCertificate(context, userData['certificatePath']),
                  icon: const Icon(Icons.file_open),
                  label: const Text('View Certificate'),
                ),
              ),
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

  Future<void> _openCertificate(BuildContext context, String filePath) async {
    try {
      print('Opening file: $filePath'); // Debug log
      final file = File(filePath);
      
      if (await file.exists()) {
        print('File exists'); // Debug log
        // Get file extension
        final extension = path.extension(filePath);
        print('File extension: $extension'); // Debug log
        
        // Check if it's an image
        if (['.jpg', '.jpeg', '.png'].contains(extension.toLowerCase())) {
          print('Opening as image'); // Debug log
          // Show image in dialog
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('Certificate'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Image.file(
                    file,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          );
        } else {
          print('Opening with system viewer'); // Debug log
          final result = await OpenFile.open(filePath);
          if (result.type != ResultType.done) {
            throw Exception('Could not open file: ${result.message}');
          }
        }
      } else {
        print('File does not exist'); // Debug log
        throw Exception('File not found at path: $filePath');
      }
    } catch (e) {
      print('Error: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coordinator')
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
          return const Center(child: Text('No pending coordinator approvals'));
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
                      onPressed: () => _approveCoordinator(requests[index].id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectCoordinator(requests[index].id),
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

  Future<void> _approveCoordinator(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isApproved': true,
    });
  }

  Future<void> _rejectCoordinator(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
  }
}
