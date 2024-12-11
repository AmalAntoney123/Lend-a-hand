import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class VolunteerDonationDetailsScreen extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> donation;

  const VolunteerDonationDetailsScreen({
    Key? key,
    required this.donationId,
    required this.donation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = (donation['startDate'] as Timestamp).toDate();
    final endDate = (donation['endDate'] as Timestamp).toDate();
    final daysLeft = endDate.difference(now).inDays;
    final isActive = endDate.isAfter(now);
    final hasStarted = startDate.isBefore(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation['title'],
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: !hasStarted
                            ? Colors.blue
                            : daysLeft < 7
                                ? Colors.red
                                : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        !hasStarted ? 'Scheduled' : 'Days left: $daysLeft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection(
                            context,
                            'Duration',
                            '${DateFormat('MMM dd, yyyy').format(startDate)} - '
                                '${DateFormat('MMM dd, yyyy').format(endDate)}',
                            Icons.calendar_today,
                          ),
                          const Divider(height: 24),
                          _buildInfoSection(
                            context,
                            'Accepts Cash',
                            donation['acceptsMoney'] ? 'Yes' : 'No',
                            Icons.attach_money,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAcceptedItemsList(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildDonationsList(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptedItemsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Accepted Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (donation['acceptedItems'] as List<dynamic>).map((item) {
            return Chip(
              label: Text(item),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDonationsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.list_alt,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Received Donations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final moneyDonations =
                data['moneyDonations'] as List<dynamic>? ?? [];
            final itemDonations = data['itemDonations'] as List<dynamic>? ?? [];

            if (moneyDonations.isEmpty && itemDonations.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Text('No donations received yet'),
                  ],
                ),
              );
            }

            // Calculate total money received
            final totalMoney = moneyDonations.fold<double>(
              0,
              (sum, donation) => sum + (donation['amount'] as num).toDouble(),
            );

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Money Donations'),
                      Tab(text: 'Item Donations'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400, // Adjust this height as needed
                    child: TabBarView(
                      children: [
                        // Money Donations Tab
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Received:',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '₹${totalMoney.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                itemCount: moneyDonations.length,
                                itemBuilder: (context, index) {
                                  final donation = moneyDonations[index];
                                  return Card(
                                    elevation: 1,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.attach_money,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                      title: Text('₹${donation['amount']}'),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Donor: ${donation['donorName']}'),
                                          Text(
                                              'Payment ID: ${donation['paymentId']}'),
                                        ],
                                      ),
                                      trailing: Text(
                                        DateFormat('MM/dd/yyyy').format(
                                            (donation['date'] as Timestamp)
                                                .toDate()),
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        // Item Donations Tab
                        ListView.builder(
                          itemCount: itemDonations.length,
                          itemBuilder: (context, index) {
                            final donation = itemDonations[index];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.inventory,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                                title: Text(donation['item']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Donor: ${donation['donorName']}'),
                                    Text(
                                        'Description: ${donation['description']}'),
                                    Text(
                                      'Status: ${donation['status'] ?? 'Pending'}',
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            donation['status'] ?? 'Pending'),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  DateFormat('MM/dd/yyyy').format(
                                      (donation['date'] as Timestamp).toDate()),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Donor Contact Details
                                        if (donation['donorId'] != null) ...[
                                          FutureBuilder<DocumentSnapshot>(
                                            future: FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(donation['donorId'])
                                                .get(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.data!.exists) {
                                                final userData =
                                                    snapshot.data!.data()
                                                        as Map<String, dynamic>;
                                                final phoneNumber =
                                                    userData['phoneNumber'];
                                                if (phoneNumber != null &&
                                                    phoneNumber.isNotEmpty) {
                                                  return ListTile(
                                                    leading:
                                                        const Icon(Icons.phone),
                                                    title: InkWell(
                                                      onTap: () => _launchCall(
                                                          phoneNumber),
                                                      child: Text(
                                                        phoneNumber,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        // Status Update Section
                                        Text(
                                          'Update Status',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            _buildStatusChip(
                                              context,
                                              donation,
                                              'Pending',
                                              Icons.hourglass_empty,
                                            ),
                                            _buildStatusChip(
                                              context,
                                              donation,
                                              'Confirmed',
                                              Icons.check_circle_outline,
                                            ),
                                            _buildStatusChip(
                                              context,
                                              donation,
                                              'Picked Up',
                                              Icons.local_shipping_outlined,
                                            ),
                                            _buildStatusChip(
                                              context,
                                              donation,
                                              'Delivered',
                                              Icons.inventory_2,
                                            ),
                                          ],
                                        ),
                                        if (donation['notes'] != null) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            'Notes:',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                          Text(donation['notes']),
                                        ],
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _addNote(context, donation),
                                          icon: const Icon(Icons.note_add),
                                          label: const Text('Add Note'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Picked Up':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(
    BuildContext context,
    Map<String, dynamic> donation,
    String status,
    IconData icon,
  ) {
    final isCurrentStatus = donation['status'] == status;
    return FilterChip(
      selected: isCurrentStatus,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isCurrentStatus ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(status),
        ],
      ),
      onSelected: (bool selected) {
        _updateDonationStatus(donation, status);
      },
    );
  }

  Future<void> _updateDonationStatus(
    Map<String, dynamic> donation,
    String newStatus,
  ) async {
    try {
      final donationRef =
          FirebaseFirestore.instance.collection('donations').doc(donationId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final donationDoc = await transaction.get(donationRef);
        final itemDonations =
            List<dynamic>.from(donationDoc.get('itemDonations'));

        final index = itemDonations.indexWhere((item) =>
            item['date'] == donation['date'] &&
            item['donorId'] == donation['donorId']);

        if (index != -1) {
          itemDonations[index]['status'] = newStatus;
          transaction.update(donationRef, {'itemDonations': itemDonations});
        }
      });
    } catch (e) {
      print('Error updating donation status: $e');
    }
  }

  Future<void> _addNote(
      BuildContext context, Map<String, dynamic> donation) async {
    final noteController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Enter note about the donation',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (noteController.text.isNotEmpty) {
                await _updateDonationNote(donation, noteController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDonationNote(
    Map<String, dynamic> donation,
    String note,
  ) async {
    try {
      final donationRef =
          FirebaseFirestore.instance.collection('donations').doc(donationId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final donationDoc = await transaction.get(donationRef);
        final itemDonations =
            List<dynamic>.from(donationDoc.get('itemDonations'));

        final index = itemDonations.indexWhere((item) =>
            item['date'] == donation['date'] &&
            item['donorId'] == donation['donorId']);

        if (index != -1) {
          itemDonations[index]['notes'] = note;
          transaction.update(donationRef, {'itemDonations': itemDonations});
        }
      });
    } catch (e) {
      print('Error updating donation note: $e');
    }
  }

  Future<void> _launchCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(' ', ''),
    );
    try {
      if (!await launchUrl(phoneUri)) {
        throw 'Could not launch $phoneUri';
      }
    } catch (e) {
      print('Error launching phone call: $e');
    }
  }
}
