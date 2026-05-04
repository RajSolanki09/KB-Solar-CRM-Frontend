// lib/Cubits/Auth/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

class AppStateCubit extends Cubit<AppState> {
  AppStateCubit() : super(SplashState());

  void showLogin() => emit(Unauthenticated());

  /// Call this after a successful login API response.
  /// Pass the full user object from the backend.
  void login({
    required UserRole role,
    required String userId,
    String userName = '',
    String? phone,
  }) => emit(
    Authenticated(role, userId: userId, userName: userName, phone: phone),
  );

  void logout() => emit(Unauthenticated());

  /// Convenience getter — null if not authenticated
  String? get currentUserId {
    final s = state;
    return s is Authenticated ? s.userId : null;
  }
}
