import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/update_service.dart';

class UpdatesScreen extends StatelessWidget {
  final UpdateService _updateService = UpdateService();

  UpdatesScreen({super.key});

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _updateService.getUpdates(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final updates = snapshot.data?.docs ?? [];
        final now = DateTime.now();

        // Filter out expired updates
        final unexpiredUpdates = updates.where((doc) {
          final update = doc.data() as Map<String, dynamic>;
          final expiryDate = update['expiryDate'] as Timestamp?;
          return expiryDate != null && expiryDate.toDate().isAfter(now);
        }).toList();

        if (unexpiredUpdates.isEmpty) {
          return const Center(
            child: Text('No active updates available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: unexpiredUpdates.length,
          itemBuilder: (context, index) {
            final update =
                unexpiredUpdates[index].data() as Map<String, dynamic>;
            final type = update['type'] as String;
            final severity = update['severity'] as String;
            final timestamp = update['timestamp'] as Timestamp;
            final expiryDate = update['expiryDate'] as Timestamp;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: type == 'weather'
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      child: Icon(
                        type == 'weather' ? Icons.cloud : Icons.warning,
                        color: type == 'weather' ? Colors.blue : Colors.red,
                      ),
                    ),
                    title: Text(
                      update['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(timestamp.toDate()),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(update['description']),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              update['location'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Expires on ${DateFormat('MMM dd, yyyy HH:mm').format(expiryDate.toDate())}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
