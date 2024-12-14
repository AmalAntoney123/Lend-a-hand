import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group.dart';
import '../../models/volunteer_call.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final bool isCoordinator;

  const GroupDetailScreen({
    Key? key,
    required this.group,
    this.isCoordinator = false,
  }) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  DateTime? _selectedDate;
  bool _isCoordinator = false;

  Future<void> _checkUserRole() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _isCoordinator = userDoc.data()?['role'] == 'coordinator';
        });
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user found');

      await FirebaseFirestore.instance.collection('group_messages').add({
        'groupId': widget.group.id,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'message',
      });

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _createVolunteerCall() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedDate = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Volunteer Call'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter event title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter event description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'No date selected'
                            : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context).then(
                        (value) => setState(() {}),
                      ),
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _titleController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty ||
                    _descriptionController.text.isEmpty ||
                    _selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('group_messages')
                      .add({
                    'groupId': widget.group.id,
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'eventDate': Timestamp.fromDate(_selectedDate!),
                    'createdAt': FieldValue.serverTimestamp(),
                    'timestamp': FieldValue.serverTimestamp(),
                    'responses': {},
                    'type': 'volunteer_call',
                    'senderId': _authService.currentUser?.uid,
                    'senderName':
                        _authService.currentUser?.displayName ?? 'Unknown',
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    _titleController.clear();
                    _descriptionController.clear();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating call: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToCall(String callId, bool accepted) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user found');

      await FirebaseFirestore.instance
          .collection('group_messages')
          .doc(callId)
          .update({
        'responses.${user.uid}': accepted,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error responding to call: $e')),
        );
      }
    }
  }

  void _showVolunteerDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Group Members',
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
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId,
                        whereIn: widget.group.volunteerIds)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final volunteers = snapshot.data!.docs;

                  if (volunteers.isEmpty) {
                    return const Center(
                      child: Text('No volunteers in this group yet'),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: volunteers.length,
                    itemBuilder: (context, index) {
                      final volunteer =
                          volunteers[index].data() as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            (volunteer['fullName'] ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(volunteer['fullName'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(volunteer['email'] ?? ''),
                            Text(volunteer['phoneNumber'] ?? 'No phone number'),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAcceptedVolunteers(Map<String, bool> responses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Accepted Volunteers',
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
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId,
                        whereIn: responses.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList())
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final volunteers = snapshot.data!.docs;

                  if (volunteers.isEmpty) {
                    return const Center(
                      child: Text('No volunteers have accepted yet'),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: volunteers.length,
                    itemBuilder: (context, index) {
                      final volunteer =
                          volunteers[index].data() as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            (volunteer['fullName'] ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(volunteer['fullName'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(volunteer['email'] ?? ''),
                            Text(volunteer['phoneNumber'] ?? 'No phone number'),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          if (_isCoordinator)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showVolunteerDetails,
            ),
        ],
      ),
      body: Column(
        children: [
          // Pinned Volunteer Calls Section
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('group_messages')
                .where('groupId', isEqualTo: widget.group.id)
                .where('type', isEqualTo: 'volunteer_call')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }

              final calls = snapshot.data!.docs;
              calls.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['timestamp']
                    as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['timestamp']
                    as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Active Volunteer Calls',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(
                      height: calls.isEmpty ? 0 : 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: calls.length,
                        itemBuilder: (context, index) {
                          final item =
                              calls[index].data() as Map<String, dynamic>;
                          final responses =
                              Map<String, bool>.from(item['responses'] ?? {});
                          final currentUserResponse =
                              responses[_authService.currentUser?.uid];
                          final eventDate =
                              (item['eventDate'] as Timestamp).toDate();

                          return Card(
                            margin: const EdgeInsets.only(right: 8, bottom: 8),
                            child: Container(
                              width: 280,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.event, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['description'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${eventDate.day}/${eventDate.month}/${eventDate.year}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${responses.values.where((v) => v).length} accepted',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          if (_isCoordinator)
                                            IconButton(
                                              icon: const Icon(Icons.info_outline,
                                                  size: 20),
                                              onPressed: () =>
                                                  _showAcceptedVolunteers(
                                                      responses),
                                            ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () => _respondToCall(
                                                calls[index].id, false),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(
                                                  color: Colors.red),
                                              backgroundColor:
                                                  currentUserResponse == false
                                                      ? Colors.red
                                                          .withOpacity(0.1)
                                                      : null,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                            child: const Text('Decline'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _respondToCall(
                                                calls[index].id, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  currentUserResponse == true
                                                      ? Colors.green
                                                      : null,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                            child: const Text('Accept'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Regular Messages Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_messages')
                  .where('groupId', isEqualTo: widget.group.id)
                  .where('type', isEqualTo: 'message')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!.docs;
                items.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp']
                      as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp']
                      as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  reverse: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index].data() as Map<String, dynamic>;
                    final isCurrentUser =
                        item['senderId'] == _authService.currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: isCurrentUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isCurrentUser)
                                  Text(
                                    item['senderName'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                Text(
                                  item['message'],
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
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
            ),
          ),
          // Message Input Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
                if (_isCoordinator)
                  IconButton(
                    icon: const Icon(Icons.add_alert),
                    onPressed: _createVolunteerCall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
