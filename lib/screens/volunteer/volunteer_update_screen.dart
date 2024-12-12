import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/update_service.dart';

class VolunteerUpdateScreen extends StatefulWidget {
  const VolunteerUpdateScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerUpdateScreen> createState() => _VolunteerUpdateScreenState();
}

class _VolunteerUpdateScreenState extends State<VolunteerUpdateScreen> {
  final UpdateService _updateService = UpdateService();
  final user = FirebaseAuth.instance.currentUser;
  bool _showOnlyMyUpdates = false;

  void _showCreateUpdateDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    String selectedType = 'weather';
    String selectedSeverity = 'low';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Update',
                      style: TextStyle(
                        fontSize: 20,
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
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'weather', child: Text('Weather Update')),
                    DropdownMenuItem(
                        value: 'disaster', child: Text('Disaster Alert')),
                  ],
                  onChanged: (value) => selectedType = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Severity Level',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                        value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (value) => selectedSeverity = value!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    hintText: 'Enter a brief title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Provide detailed information',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                    hintText: 'Enter the affected area',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () async {
                      if (titleController.text.isEmpty ||
                          descriptionController.text.isEmpty ||
                          locationController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      try {
                        await _updateService.createUpdate(
                          title: titleController.text,
                          description: descriptionController.text,
                          type: selectedType,
                          location: locationController.text,
                          severity: selectedSeverity,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Update submitted for approval'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Submit Update'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildUpdateCard(DocumentSnapshot doc) {
    final update = doc.data() as Map<String, dynamic>;
    final type = update['type'] as String;
    final severity = update['severity'] as String;
    final timestamp = update['timestamp'] as Timestamp;
    final status = update['status'] as String;
    final expiryDate = update['expiryDate'] as Timestamp?;
    final now = DateTime.now();

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
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      update['location'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (expiryDate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getExpiryBackgroundColor(expiryDate.toDate(), now),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: _getExpiryTextColor(expiryDate.toDate(), now),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getExpiryText(expiryDate.toDate(), now),
                    style: TextStyle(
                      color: _getExpiryTextColor(expiryDate.toDate(), now),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getExpiryBackgroundColor(DateTime expiryDate, DateTime now) {
    final difference = expiryDate.difference(now);
    if (difference.isNegative) {
      return Colors.red.withOpacity(0.1);
    } else if (difference.inHours < 24) {
      return Colors.orange.withOpacity(0.1);
    } else {
      return Colors.green.withOpacity(0.1);
    }
  }

  Color _getExpiryTextColor(DateTime expiryDate, DateTime now) {
    final difference = expiryDate.difference(now);
    if (difference.isNegative) {
      return Colors.red;
    } else if (difference.inHours < 24) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getExpiryText(DateTime expiryDate, DateTime now) {
    final difference = expiryDate.difference(now);
    
    if (difference.isNegative) {
      return 'Expired ${DateFormat.yMMMd().add_jm().format(expiryDate)}';
    }
    
    if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'Expires in ${difference.inMinutes} minutes';
    } else {
      return 'Expires in ${difference.inSeconds} seconds';
    }
  }

  Widget _buildUpdatesList(Stream<QuerySnapshot> updatesStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: updatesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final updates = snapshot.data?.docs ?? [];
        final now = DateTime.now();

        // Filter out expired updates unless they belong to the current user
        final filteredUpdates = updates.where((doc) {
          final update = doc.data() as Map<String, dynamic>;
          final expiryDate = update['expiryDate'] as Timestamp?;
          final isOwnUpdate = update['authorId'] == user?.uid;

          // Always show user's own updates
          if (_showOnlyMyUpdates && isOwnUpdate) return true;
          
          // For general feed, only show non-expired updates
          if (!_showOnlyMyUpdates) {
            if (expiryDate == null) return false;
            return expiryDate.toDate().isAfter(now);
          }

          return false;
        }).toList();

        if (filteredUpdates.isEmpty) {
          return const Center(
            child: Text('No updates available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUpdates.length,
          itemBuilder: (context, index) {
            return _buildUpdateCard(filteredUpdates[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Show my submissions'),
                const SizedBox(width: 8),
                Switch(
                  value: _showOnlyMyUpdates,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyMyUpdates = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildUpdatesList(_updateService.getUpdates(
              filterByUser: _showOnlyMyUpdates ? user?.uid : null,
            )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUpdateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Update'),
      ),
    );
  }
}
