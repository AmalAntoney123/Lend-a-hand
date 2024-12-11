import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/donation_service.dart';
import 'donation_details_screen.dart';

class CoordinatorDonateScreen extends StatelessWidget {
  const CoordinatorDonateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showCreateDonationDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Donation Request'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Donations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Active Donations'),
                      Tab(text: 'Past Donations'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onBackground,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDonationsList(true),
                        _buildDonationsList(false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDonationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final itemsController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    bool acceptsMoney = false;
    List<String> selectedVolunteers = [];
    final donationService = DonationService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create Donation Request',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Donation Title',
                        hintText: 'Enter donation campaign title',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => startDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(startDate == null
                                ? 'Start Date'
                                : DateFormat('MM/dd/yyyy').format(startDate!)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: startDate ?? DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => endDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(endDate == null
                                ? 'End Date'
                                : DateFormat('MM/dd/yyyy').format(endDate!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Accept Money Donations'),
                      value: acceptsMoney,
                      onChanged: (bool? value) {
                        setState(() {
                          acceptsMoney = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: itemsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Accepted Items',
                        hintText:
                            'Enter items accepted as donations (comma-separated)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Assign Volunteers',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: donationService.getApprovedVolunteers(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        final volunteers = snapshot.data!.docs;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          height: 150,
                          child: ListView.builder(
                            itemCount: volunteers.length,
                            itemBuilder: (context, index) {
                              final volunteer = volunteers[index].data()
                                  as Map<String, dynamic>;
                              final volunteerId = volunteers[index].id;

                              return CheckboxListTile(
                                title: Text(volunteer['fullName'] ?? 'Unknown'),
                                subtitle: Text(volunteer['email'] ?? ''),
                                value: selectedVolunteers.contains(volunteerId),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedVolunteers.add(volunteerId);
                                    } else {
                                      selectedVolunteers.remove(volunteerId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isNotEmpty &&
                              startDate != null &&
                              endDate != null &&
                              itemsController.text.isNotEmpty) {
                            try {
                              await donationService.createDonation(
                                title: titleController.text,
                                startDate: startDate!,
                                endDate: endDate!,
                                acceptedItems: itemsController.text
                                    .split(',')
                                    .map((e) => e.trim())
                                    .toList(),
                                acceptsMoney: acceptsMoney,
                                assignedVolunteers: selectedVolunteers,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Donation created successfully'),
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
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Create Donation'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDonationsList(bool isActive) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final donations = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final endDate = (data['endDate'] as Timestamp).toDate();

          if (isActive) {
            return endDate.isAfter(now);
          } else {
            return endDate.isBefore(now);
          }
        }).toList();

        if (donations.isEmpty) {
          return Center(
            child: Text(
              isActive ? 'No active donations' : 'No past donations',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index].data() as Map<String, dynamic>;
            final startDate = (donation['startDate'] as Timestamp).toDate();
            final endDate = (donation['endDate'] as Timestamp).toDate();
            final daysLeft = endDate.difference(now).inDays;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: const Icon(Icons.volunteer_activism),
                title: Text(donation['title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('MM/dd/yyyy').format(startDate)} - '
                      '${DateFormat('MM/dd/yyyy').format(endDate)}',
                    ),
                    if (isActive)
                      Text(
                        startDate.isAfter(now)
                            ? 'Scheduled'
                            : 'Days left: $daysLeft',
                        style: TextStyle(
                          color: startDate.isAfter(now)
                              ? Colors.blue
                              : (daysLeft < 7 ? Colors.red : Colors.green),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationDetailsScreen(
                        donationId: donations[index].id,
                        donation: donation,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
