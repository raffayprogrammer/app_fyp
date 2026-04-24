enum UserRole { user, admin }

class UserModel {
  final String uid;
  final String email;
  final String cnic;
  final String fullName;
  final UserRole role;
  final bool isEmailVerified;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.cnic,
    required this.fullName,
    required this.role,
    required this.isEmailVerified,
    required this.createdAt,
  });
}
