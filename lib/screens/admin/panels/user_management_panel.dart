import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lendahand/theme/app_theme.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class UserManagementPanel extends StatefulWidget {
  const UserManagementPanel({Key? key}) : super(key: key);

  @override
  State<UserManagementPanel> createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<UserManagementPanel> {
  String _searchQuery = '';
  String _selectedRole = 'All';
  bool _showOnlyApproved = false;
  final List<String> _roles = ['All', 'Coordinator', 'Volunteer', 'Commoner'];

  void _showUserDetails(Map<String, dynamic> userData) {
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
            _detailRow('Role',
                userData['role']?.toString().toUpperCase() ?? 'Not provided'),
            _detailRow('Status',
                userData['isApproved'] == true ? 'Approved' : 'Pending'),
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

  Future<void> _toggleUserStatus(String userId, bool isDisabled) async {
    final action = isDisabled ? 'Enable' : 'Disable';
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action.capitalize(),
              style: TextStyle(
                color: isDisabled ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isDisabled': !isDisabled,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('User ${isDisabled ? 'enabled' : 'disabled'} successfully'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search and Filter Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.secondaryYellow),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedRole,
                        items: _roles
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Show only approved users'),
                          value: _showOnlyApproved,
                          onChanged: (value) {
                            setState(() {
                              _showOnlyApproved = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Users Cards
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data?.docs ?? [];
                final filteredUsers = users.where((doc) {
                  final userData = doc.data() as Map<String, dynamic>;
                  final searchMatch = userData['fullName']
                          ?.toString()
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ??
                      false ||
                          userData['email']!
                              .toString()
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase());

                  final roleMatch = _selectedRole == 'All' ||
                      userData['role']?.toString().toLowerCase() ==
                          _selectedRole.toLowerCase();

                  return searchMatch && roleMatch;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final userData =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondaryYellow,
                          child: Text(
                            (userData['fullName'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(userData['fullName'] ?? 'No name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userData['phoneNumber'] ?? 'No phone'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: userData['isApproved'] == true
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    userData['isApproved'] == true
                                        ? 'Approved'
                                        : 'Pending',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (userData['isDisabled'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Disabled',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => _showUserDetails(userData),
                            ),
                            IconButton(
                              icon: Icon(
                                userData['isDisabled'] == true
                                    ? Icons.check_circle
                                    : Icons.block,
                                color: userData['isDisabled'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              onPressed: () => _toggleUserStatus(
                                filteredUsers[index].id,
                                userData['isDisabled'] == true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isNotEqualTo: 'admin');

    if (_showOnlyApproved) {
      query = query.where('isApproved', isEqualTo: true);
    }

    return query.snapshots();
  }
}
