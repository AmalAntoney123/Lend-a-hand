class VolunteerCall {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final DateTime eventDate;
  final DateTime createdAt;
  final Map<String, bool> responses; // volunteerId: accepted

  VolunteerCall({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.createdAt,
    required this.responses,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'eventDate': eventDate,
      'createdAt': createdAt,
      'responses': responses,
    };
  }

  factory VolunteerCall.fromMap(Map<String, dynamic> map) {
    return VolunteerCall(
      id: map['id'],
      groupId: map['groupId'],
      title: map['title'],
      description: map['description'],
      eventDate: map['eventDate'].toDate(),
      createdAt: map['createdAt'].toDate(),
      responses: Map<String, bool>.from(map['responses']),
    );
  }
}
