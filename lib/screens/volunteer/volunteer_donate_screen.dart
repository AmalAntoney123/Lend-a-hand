import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/donation_service.dart';
import 'volunteer_donation_details_screen.dart';

class VolunteerDonateScreen extends StatelessWidget {
  const VolunteerDonateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final donationService = DonationService();

    if (currentUserId == null) {
      return const Center(child: Text('Please login to view your donations'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: donationService.getVolunteerAssignedDonations(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final donations = snapshot.data?.docs ?? [];

        if (donations.isEmpty) {
          return const Center(
            child: Text('No donations assigned to you yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index].data() as Map<String, dynamic>;
            final now = DateTime.now();
            final startDate = (donation['startDate'] as Timestamp).toDate();
            final endDate = (donation['endDate'] as Timestamp).toDate();
            final daysLeft = endDate.difference(now).inDays;
            final hasStarted = startDate.isBefore(now);
            final isActive = endDate.isAfter(now);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      donation['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('MMM dd, yyyy').format(startDate)} - '
                      '${DateFormat('MMM dd, yyyy').format(endDate)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: !hasStarted
                                ? Colors.blue
                                : !isActive
                                    ? Colors.grey
                                    : daysLeft < 7
                                        ? Colors.red
                                        : Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            !hasStarted
                                ? 'Upcoming'
                                : !isActive
                                    ? 'Completed'
                                    : '$daysLeft days left',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VolunteerDonationDetailsScreen(
                                donationId: donations[index].id,
                                donation: donation,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accepted Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (donation['acceptedItems'] as List<dynamic>)
                              .map((item) => Chip(
                                    label: Text(item),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    labelStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ))
                              .toList(),
                        ),
                        if (donation['acceptsMoney'])
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              '✓ Accepts money donations',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
