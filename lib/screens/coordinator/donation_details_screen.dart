import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/donation_service.dart';

class DonationDetailsScreen extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> donation;

  const DonationDetailsScreen({
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDonationDialog(context),
          ),
        ],
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
                            '${DateFormat('MMM dd, yyyy').format((donation['startDate'] as Timestamp).toDate())} - '
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

  void _showEditDonationDialog(BuildContext context) {
    final titleController = TextEditingController(text: donation['title']);
    final itemsController = TextEditingController(
      text: donation['acceptedItems'] != null
          ? (donation['acceptedItems'] as List<dynamic>).join(', ')
          : '',
    );
    DateTime startDate = (donation['startDate'] as Timestamp).toDate();
    DateTime endDate = (donation['endDate'] as Timestamp).toDate();
    bool acceptsMoney = donation['acceptsMoney'] ?? false;
    bool isBloodDonation = donation['isBloodDonation'] ?? false;
    List<String> selectedBloodGroups = List<String>.from(
      donation['requiredBloodGroups'] ?? [],
    );
    List<String> selectedVolunteers = List<String>.from(
      donation['assignedVolunteers'] ?? [],
    );

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                          'Edit Donation',
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
                                initialDate: startDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => startDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                                DateFormat('MM/dd/yyyy').format(startDate)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => endDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label:
                                Text(DateFormat('MM/dd/yyyy').format(endDate)),
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
                        controlAffinity: ListTileControlAffinity.leading,
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
                            selected: selectedBloodGroups.contains(group),
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
                    // ... Volunteer selection section remains the same ...

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a title')),
                            );
                            return;
                          }

                          if (isBloodDonation && selectedBloodGroups.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please select at least one blood group'),
                              ),
                            );
                            return;
                          }

                          if (!isBloodDonation &&
                              itemsController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter accepted items')),
                            );
                            return;
                          }

                          try {
                            await FirebaseFirestore.instance
                                .collection('donations')
                                .doc(donationId)
                                .update({
                              'title': titleController.text,
                              'startDate': Timestamp.fromDate(startDate),
                              'endDate': Timestamp.fromDate(endDate),
                              'isBloodDonation': isBloodDonation,
                              'acceptedItems': isBloodDonation
                                  ? null
                                  : itemsController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                              'requiredBloodGroups':
                                  isBloodDonation ? selectedBloodGroups : null,
                              'acceptsMoney': acceptsMoney,
                              'assignedVolunteers': selectedVolunteers,
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Donation updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating donation: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Update Donation'),
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
    final isBloodDonation = donation['isBloodDonation'] ?? false;

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
                isBloodDonation ? Icons.bloodtype : Icons.inventory_2,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isBloodDonation ? 'Required Blood Groups' : 'Accepted Items',
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
          children: isBloodDonation
              ? (donation['requiredBloodGroups'] as List<dynamic>)
                  .map((group) => Chip(
                        label: Text(group),
                        backgroundColor: Colors.red[100],
                        labelStyle: const TextStyle(color: Colors.red),
                      ))
                  .toList()
              : (donation['acceptedItems'] as List<dynamic>)
                  .map((item) => Chip(
                        label: Text(item),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ))
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildDonationsList(BuildContext context) {
    final isBloodDonation = donation['isBloodDonation'] as bool? ?? false;

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
                isBloodDonation ? Icons.bloodtype : Icons.list_alt,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isBloodDonation
                  ? 'Interested Blood Donors'
                  : 'Received Donations',
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

            if (isBloodDonation) {
              final interestedDonors =
                  (data['interestedDonors'] as List<dynamic>?) ?? [];

              if (interestedDonors.isEmpty) {
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
                      Text('No interested donors yet'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: interestedDonors.length,
                itemBuilder: (context, index) {
                  final donor = interestedDonors[index] as Map<String, dynamic>;
                  final date = (donor['date'] as Timestamp).toDate();

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(donor['name'] ?? 'Anonymous'),
                      subtitle: Text(
                        'Interested since: ${DateFormat('MMM dd, yyyy').format(date)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () =>
                            _showDonorDetailsDialog(context, donor),
                      ),
                    ),
                  );
                },
              );
            } else {
              final moneyDonations =
                  data['moneyDonations'] as List<dynamic>? ?? [];
              final itemDonations =
                  data['itemDonations'] as List<dynamic>? ?? [];

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
                      height: 400,
                      child: TabBarView(
                        children: [
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      '₹${totalMoney.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
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
                                        subtitle: Text(donation['donorName']),
                                        trailing: Text(
                                          DateFormat('MM/dd/yyyy').format(
                                              (donation['date'] as Timestamp)
                                                  .toDate()),
                                        ),
                                        onTap: () => _showDonationDetails(
                                            context, donation, 'money'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          ListView.builder(
                            itemCount: itemDonations.length,
                            itemBuilder: (context, index) {
                              final donation = itemDonations[index];
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.inventory),
                                  ),
                                  title: Text(donation['item']),
                                  subtitle: Text(donation['donorName']),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                              donation['status'] ?? 'Pending')
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      donation['status'] ?? 'Pending',
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            donation['status'] ?? 'Pending'),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _showDonationDetails(
                                      context, donation, 'item'),
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
            }
          },
        ),
      ],
    );
  }

  void _showDonationDetails(
      BuildContext context, Map<String, dynamic> donation, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          type == 'money'
                              ? Icons.payments_outlined
                              : Icons.inventory_2_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          type == 'money'
                              ? 'Money Donation Details'
                              : 'Item Donation Details',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (type == 'item') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _getStatusColor(donation['status'] ?? 'Pending')
                                    .withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(donation['status'] ?? 'Pending'),
                              color: _getStatusColor(
                                  donation['status'] ?? 'Pending'),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  donation['status'] ?? 'Pending',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: _getStatusColor(
                                            donation['status'] ?? 'Pending'),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Donor Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      'Name',
                      donation['donorName'],
                      Icons.badge_outlined,
                    ),
                    if (donation['donorId'] != null) ...[
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(donation['donorId'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            return Column(
                              children: [
                                if (userData['phoneNumber'] != null)
                                  _buildDetailRow(
                                    context,
                                    'Phone',
                                    userData['phoneNumber'],
                                    Icons.phone_outlined,
                                    isPhone: true,
                                  ),
                                if (userData['email'] != null)
                                  _buildDetailRow(
                                    context,
                                    'Email',
                                    userData['email'],
                                    Icons.email_outlined,
                                  ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                    const Divider(height: 32),
                    Text(
                      'Donation Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (type == 'money') ...[
                      _buildDetailRow(
                        context,
                        'Amount',
                        '₹${donation['amount']}',
                        Icons.currency_rupee,
                      ),
                      _buildDetailRow(
                        context,
                        'Payment ID',
                        donation['paymentId'],
                        Icons.receipt_long_outlined,
                      ),
                    ] else ...[
                      _buildDetailRow(
                        context,
                        'Item',
                        donation['item'],
                        Icons.category_outlined,
                      ),
                      _buildDetailRow(
                        context,
                        'Description',
                        donation['description'],
                        Icons.description_outlined,
                      ),
                    ],
                    _buildDetailRow(
                      context,
                      'Date',
                      DateFormat('MMM dd, yyyy')
                          .format((donation['date'] as Timestamp).toDate()),
                      Icons.calendar_today_outlined,
                    ),
                    if (type == 'item' && donation['notes'] != null) ...[
                      const Divider(height: 32),
                      Text(
                        'Additional Notes',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        donation['notes'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isPhone
                ? InkWell(
                    onTap: () => _launchCall(value),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_outlined;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'picked up':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all;
      default:
        return Icons.info_outline;
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

  void _showDonorDetailsDialog(
      BuildContext context, Map<String, dynamic> donor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Donor Details',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(donor['userId'])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text('User details not found');
                        }

                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Card (Read-only for coordinator)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _getStatusColor(
                                          donor['status'] ?? 'Pending')
                                      .withOpacity(0.5),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(
                                        donor['status'] ?? 'Pending'),
                                    color: _getStatusColor(
                                        donor['status'] ?? 'Pending'),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        donor['status'] ?? 'Pending',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: _getStatusColor(
                                                  donor['status'] ?? 'Pending'),
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // User Details
                            Text(
                              'Personal Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              context,
                              'Name',
                              userData['name'] ?? 'N/A',
                              Icons.person_outline,
                            ),
                            if (userData['phoneNumber'] != null)
                              _buildDetailRow(
                                context,
                                'Phone',
                                userData['phoneNumber'],
                                Icons.phone_outlined,
                                isPhone: true,
                              ),
                            if (userData['email'] != null)
                              _buildDetailRow(
                                context,
                                'Email',
                                userData['email'],
                                Icons.email_outlined,
                              ),
                            if (userData['bloodGroup'] != null)
                              _buildDetailRow(
                                context,
                                'Blood Group',
                                userData['bloodGroup'],
                                Icons.bloodtype_outlined,
                              ),
                            const Divider(height: 32),
                            // Donation Date
                            Text(
                              'Donation Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              context,
                              'Registered Date',
                              DateFormat('MMM dd, yyyy').format(
                                (donor['date'] as Timestamp).toDate(),
                              ),
                              Icons.calendar_today_outlined,
                            ),
                            if (donor['notes'] != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Notes',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  donor['notes'],
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
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

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Blood Donation Interest Follow-up',
        'body':
            'Dear Donor,\n\nThank you for expressing interest in blood donation...',
      },
    );

    try {
      if (!await launchUrl(emailUri)) {
        throw 'Could not launch email';
      }
    } catch (e) {
      print('Error launching email: $e');
    }
  }
}
