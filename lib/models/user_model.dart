enum UserRole {
  admin,
  coordinator,
  volunteer,
  commoner,
}

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String? name;
  final String? phone;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.commoner,
      ),
      name: data['name'],
      phone: data['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role.toString().split('.').last,
      'name': name,
      'phone': phone,
    };
  }
}
