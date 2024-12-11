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
    bool isBloodDonation = false;
    List<String> selectedVolunteers = [];
    List<String> selectedBloodGroups = [];
    final donationService = DonationService();

    final List<String> bloodGroups = [
      'A+',
      'A-',
      'B+',
      'B-',
      'O+',
      'O-',
      'AB+',
      'AB-'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 500, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                          setState(() {
                                            startDate = date;
                                            if (endDate != null &&
                                                date.isAfter(endDate!)) {
                                              endDate = null;
                                            }
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(
                                        startDate == null
                                            ? 'Start Date *'
                                            : DateFormat('MM/dd/yyyy')
                                                .format(startDate!),
                                        style: TextStyle(
                                          color: startDate == null
                                              ? Colors.red
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        if (startDate == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Please select a start date first'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.red,
                                              margin: EdgeInsets.all(16),
                                            ),
                                          );
                                          return;
                                        }
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: startDate!,
                                          firstDate: startDate!,
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 365)),
                                        );
                                        if (date != null) {
                                          setState(() => endDate = date);
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(
                                        endDate == null
                                            ? 'End Date *'
                                            : DateFormat('MM/dd/yyyy')
                                                .format(endDate!),
                                        style: TextStyle(
                                          color: endDate == null
                                              ? Colors.red
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('Blood Donation Campaign'),
                                value: isBloodDonation,
                                onChanged: (bool value) {
                                  setState(() {
                                    isBloodDonation = value;
                                    if (value) {
                                      acceptsMoney = false;
                                    }
                                  });
                                },
                              ),
                              if (!isBloodDonation) ...[
                                CheckboxListTile(
                                  title: const Text('Accept Money Donations'),
                                  value: acceptsMoney,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      acceptsMoney = value ?? false;
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                                TextField(
                                  controller: itemsController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Accepted Items',
                                    hintText:
                                        'Enter items accepted as donations (comma-separated)',
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Select Required Blood Groups',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: bloodGroups.map((group) {
                                    return FilterChip(
                                      label: Text(group),
                                      selected:
                                          selectedBloodGroups.contains(group),
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedBloodGroups.add(group);
                                          } else {
                                            selectedBloodGroups.remove(group);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
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
                                        final volunteer = volunteers[index]
                                            .data() as Map<String, dynamic>;
                                        final volunteerId =
                                            volunteers[index].id;

                                        return CheckboxListTile(
                                          title: Text(volunteer['fullName'] ??
                                              'Unknown'),
                                          subtitle:
                                              Text(volunteer['email'] ?? ''),
                                          value: selectedVolunteers
                                              .contains(volunteerId),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                selectedVolunteers
                                                    .add(volunteerId);
                                              } else {
                                                selectedVolunteers
                                                    .remove(volunteerId);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Add print statements for debugging
                            print('Title: ${titleController.text}');
                            print('Start Date: $startDate');
                            print('End Date: $endDate');
                            print('Is Blood Donation: $isBloodDonation');
                            print(
                                'Selected Blood Groups: $selectedBloodGroups');
                            print('Items: ${itemsController.text}');
                            print('Accepts Money: $acceptsMoney');
                            print('Selected Volunteers: $selectedVolunteers');

                            if (titleController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a title'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (startDate == null || endDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please select both start and end dates'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (isBloodDonation &&
                                selectedBloodGroups.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please select at least one blood group'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (!isBloodDonation &&
                                itemsController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter accepted items'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              await donationService.createDonation(
                                title: titleController.text,
                                startDate: startDate!,
                                endDate: endDate!,
                                acceptedItems: isBloodDonation
                                    ? null
                                    : itemsController.text
                                        .split(',')
                                        .map((e) => e.trim())
                                        .where((e) => e.isNotEmpty)
                                        .toList(),
                                requiredBloodGroups: isBloodDonation
                                    ? selectedBloodGroups
                                    : null,
                                acceptsMoney: acceptsMoney,
                                assignedVolunteers: selectedVolunteers,
                                isBloodDonation: isBloodDonation,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Donation created successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              print('Error creating donation: $e');
                              if (context.mounted) {
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
                    ],
                  ),
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
            final isBloodDonation = donation['isBloodDonation'] ?? false;
            final startDate = (donation['startDate'] as Timestamp).toDate();
            final endDate = (donation['endDate'] as Timestamp).toDate();
            final daysLeft = endDate.difference(now).inDays;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: Icon(
                  isBloodDonation ? Icons.bloodtype : Icons.volunteer_activism,
                  color: isBloodDonation ? Colors.red : null,
                ),
                title: Text(donation['title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('MM/dd/yyyy').format(startDate)} - '
                      '${DateFormat('MM/dd/yyyy').format(endDate)}',
                    ),
                    if (isBloodDonation)
                      Wrap(
                        spacing: 4,
                        children:
                            (donation['requiredBloodGroups'] as List<dynamic>)
                                .map((group) => Chip(
                                      label: Text(group),
                                      backgroundColor: Colors.red[100],
                                      labelStyle:
                                          const TextStyle(color: Colors.red),
                                    ))
                                .toList(),
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
