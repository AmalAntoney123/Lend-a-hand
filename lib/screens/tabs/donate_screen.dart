import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/donation_service.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({Key? key}) : super(key: key);

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  late Razorpay _razorpay;
  String? donationId;
  int? amountInPaise;
  bool isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Add the donation record to Firestore
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        'moneyDonations': FieldValue.arrayUnion([
          {
            'amount': amountInPaise! / 100, // Convert back to rupees
            'donorId': currentUser.uid,
            'donorName': isAnonymous ? null : currentUser.displayName,
            'date': Timestamp.now(),
            'paymentId': response.paymentId,
          }
        ]),
      });

      if (!mounted) return;
      Navigator.pop(context); // Close the donation dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your generous donation!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording donation: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    Navigator.pop(context); // Close the donation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed please try again'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet Selected: ${response.walletName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationService = DonationService();

    return StreamBuilder<QuerySnapshot>(
      stream: donationService.getActiveDonations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final donations = snapshot.data?.docs ?? [];

        final currentDonations = donations.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final startDate = (data['startDate'] as Timestamp).toDate();
          final endDate = (data['endDate'] as Timestamp).toDate();
          return startDate.isBefore(now) && endDate.isAfter(now);
        }).toList();

        final upcomingDonations = donations.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final startDate = (data['startDate'] as Timestamp).toDate();
          return startDate.isAfter(now);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (currentDonations.isNotEmpty) ...[
              const Text(
                'Current Donations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...currentDonations.map((doc) {
                final donation = doc.data() as Map<String, dynamic>;
                return _buildDonationCard(context, doc.id, donation, true);
              }).toList(),
            ],
            if (upcomingDonations.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Upcoming Donations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...upcomingDonations.map((doc) {
                final donation = doc.data() as Map<String, dynamic>;
                return _buildDonationCard(context, doc.id, donation, false);
              }).toList(),
            ],
            if (currentDonations.isEmpty && upcomingDonations.isEmpty)
              const Center(
                child: Text(
                  'No active donation campaigns at the moment.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDonationCard(BuildContext context, String donationId,
      Map<String, dynamic> donation, bool isCurrent) {
    final now = DateTime.now();
    final startDate = (donation['startDate'] as Timestamp).toDate();
    final endDate = (donation['endDate'] as Timestamp).toDate();
    final daysLeft = endDate.difference(now).inDays;
    final isBloodDonation = donation['isBloodDonation'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              isBloodDonation ? Icons.bloodtype : Icons.volunteer_activism,
              color: isBloodDonation ? Colors.red : null,
            ),
            title: Text(
              donation['title'] ?? 'Untitled Donation',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('MMM dd, yyyy').format(startDate)} - '
                  '${DateFormat('MMM dd, yyyy').format(endDate)}',
                ),
                if (isCurrent)
                  Text(
                    'Days left: $daysLeft',
                    style: TextStyle(
                      color: daysLeft < 7 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (isCurrent) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBloodDonation) ...[
                    const Text(
                      'Required Blood Groups:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (donation['requiredBloodGroups'] as List<dynamic>?)
                                  ?.map((group) => Chip(
                                        label: Text(group.toString()),
                                        backgroundColor: Colors.red[100],
                                        labelStyle:
                                            const TextStyle(color: Colors.red),
                                      ))
                                  .toList() ??
                              [],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showBloodDonationInterestDialog(
                            context, donationId),
                        icon: const Icon(Icons.favorite),
                        label: const Text('Express Interest in Donating'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Items Needed:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (donation['acceptedItems'] as List<dynamic>?)
                              ?.map((item) => Chip(
                                    label: Text(item.toString()),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    labelStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ))
                              .toList() ??
                          [],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showItemDonationDialog(
                                context, donationId, donation),
                            icon: const Icon(Icons.inventory),
                            label: const Text('Donate Items'),
                          ),
                        ),
                        if (donation['acceptsMoney'] as bool? ?? false) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showMoneyDonationDialog(context, donationId),
                              icon: const Icon(Icons.attach_money),
                              label: const Text('Donate Money'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showItemDonationDialog(
      BuildContext context, String donationId, Map<String, dynamic> donation) {
    final itemController = TextEditingController();
    String? selectedItem;
    final currentUser = FirebaseAuth.instance.currentUser;
    List<Map<String, String>> itemsToAdd = [];
    bool isAnonymous = false;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to donate')),
      );
      return;
    }

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
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                          'Donate Items',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    if (itemsToAdd.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Items to Donate:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.2,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: itemsToAdd.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                title: Text(itemsToAdd[index]['item']!),
                                subtitle:
                                    Text(itemsToAdd[index]['description']!),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      itemsToAdd.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedItem,
                      decoration: const InputDecoration(
                        labelText: 'Select Item to Donate',
                        border: OutlineInputBorder(),
                      ),
                      items: (donation['acceptedItems'] as List<dynamic>)
                          .map((item) => DropdownMenuItem(
                                value: item.toString(),
                                child: Text(item.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedItem = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: itemController,
                      decoration: const InputDecoration(
                        labelText: 'Item Description',
                        hintText: 'Describe the condition, quantity, etc.',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (selectedItem != null &&
                                  itemController.text.isNotEmpty) {
                                setState(() {
                                  itemsToAdd.add({
                                    'item': selectedItem!,
                                    'description': itemController.text,
                                  });
                                  selectedItem = null;
                                  itemController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      title: const Text('Make donation anonymous'),
                      value: isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          isAnonymous = value ?? false;
                        });
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: itemsToAdd.isEmpty
                            ? null
                            : () async {
                                try {
                                  final batch =
                                      FirebaseFirestore.instance.batch();
                                  final donationRef = FirebaseFirestore.instance
                                      .collection('donations')
                                      .doc(donationId);

                                  for (var item in itemsToAdd) {
                                    batch.update(donationRef, {
                                      'itemDonations': FieldValue.arrayUnion([
                                        {
                                          'item': item['item'],
                                          'description': item['description'],
                                          'donorId': currentUser.uid,
                                          'donorName': isAnonymous
                                              ? null
                                              : currentUser.displayName,
                                          'date': Timestamp.now(),
                                        }
                                      ]),
                                    });
                                  }

                                  await batch.commit();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Thank you for your donation!'),
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
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Submit All Donations'),
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

  void _showMoneyDonationDialog(BuildContext context, String donationId) {
    final amountController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isAnonymous = false;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to donate')),
      );
      return;
    }

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
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Donate Money',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text('Make donation anonymous'),
                    value: isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        isAnonymous = value ?? false;
                      });
                    },
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      hintText: 'Enter amount in INR',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (amountController.text.isNotEmpty) {
                          try {
                            final amount = double.parse(amountController.text);
                            this.donationId = donationId;
                            this.amountInPaise = (amount * 100).toInt();
                            this.isAnonymous = isAnonymous;

                            var options = {
                              'key': 'rzp_test_VXGvAZXTjjjCQQ',
                              'amount': amountInPaise,
                              'name': 'Donation',
                              'description': 'Donation to campaign',
                              'currency': 'INR',
                              'prefill': {
                                'contact': currentUser.phoneNumber ?? '',
                                'email': currentUser.email ?? '',
                                'name': currentUser.displayName ?? '',
                              }
                            };

                            _razorpay.open(options);
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
                        child: Text('Donate'),
                      ),
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

  void _showBloodDonationInterestDialog(
      BuildContext context, String donationId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to express interest')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Express Interest in Blood Donation'),
          content: const Text(
            'By expressing interest, you agree to be contacted by our coordinator '
            'to arrange the blood donation. They will contact you using your registered '
            'phone number or email.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('donations')
                      .doc(donationId)
                      .update({
                    'interestedDonors': FieldValue.arrayUnion([
                      {
                        'userId': currentUser.uid,
                        'name': currentUser.displayName,
                        'email': currentUser.email,
                        'date': Timestamp.now(),
                      }
                    ]),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Thank you for your interest! Our coordinator will contact you soon.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Interest'),
            ),
          ],
        );
      },
    );
  }
}
