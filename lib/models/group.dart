class Group {
  final String id;
  final String name;
  final String coordinatorId;
  final List<String> volunteerIds;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.coordinatorId,
    required this.volunteerIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coordinatorId': coordinatorId,
      'volunteerIds': volunteerIds,
      'createdAt': createdAt,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      coordinatorId: map['coordinatorId'],
      volunteerIds: List<String>.from(map['volunteerIds']),
      createdAt: map['createdAt'].toDate(),
    );
  }
}
