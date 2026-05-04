// lib/Cubits/Auth/auth_state.dart

enum UserRole { admin, sales, service, installation }

abstract class AppState {}

class SplashState extends AppState {}

class Unauthenticated extends AppState {}

class Authenticated extends AppState {
  final UserRole role;
  final String userId;   // MongoDB _id of the logged-in user
  final String userName; // display name
  final String? phone;

  Authenticated(this.role, {
    required this.userId,
    this.userName = '',
    this.phone,
  });
}