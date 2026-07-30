/// A user of the app, which can be a teacher or a student.
class User {
  final int? id;
  final String fullName;
  final String username;
  final String password;
  final String role;
  final bool isActive;

  User({
    this.id,
    required this.fullName,
    required this.username,
    required this.password,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'password': password,
      'role': role,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  User copyWith({
    int? id,
    String? fullName,
    String? username,
    String? password,
    String? role,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, role: $role, isActive: $isActive)';
  }
}
