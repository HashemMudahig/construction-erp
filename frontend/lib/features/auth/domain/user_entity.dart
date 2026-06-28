/// Authenticated user entity.
class UserEntity {
  UserEntity({required this.email, required this.token});

  final String email;
  final String token;

  UserEntity copyWith({String? email, String? token}) =>
      UserEntity(email: email ?? this.email, token: token ?? this.token);
}