import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/auth_repository.dart';
import '../domain/user_entity.dart';

/// Auth session state. Holds the logged-in user or null.
class AuthSession {
  AuthSession({this.user, this.isLoading = false, this.error});
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  bool get isLoggedIn => user != null;

  AuthSession copyWith({UserEntity? user, bool? isLoading, String? error}) =>
      AuthSession(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

/// StateNotifier-based auth session provider. Persists token via
/// `shared_preferences` (through dio_provider helpers).
class AuthSessionNotifier extends StateNotifier<AuthSession> {
  AuthSessionNotifier(this._ref) : super(AuthSession()) {
    _restoreSession();
  }

  final Ref _ref;

  Future<void> _restoreSession() async {
    final token = await readToken();
    if (token != null && token.isNotEmpty) {
      // We have a stored token; treat as logged in. The email is also stored.
      // A robust implementation would validate the token; for v1 we trust it.
      state = AuthSession(user: UserEntity(email: '', token: token));
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _ref.read(authRepositoryProvider).login(
            LoginRequest(email: email, password: password),
          );
      await writeToken(res.accessToken, email);
      state = AuthSession(
        user: UserEntity(email: email, token: res.accessToken),
      );
      return true;
    } on DioException catch (e) {
      final apiError = e.error;
      String message = 'Login failed';
      if (apiError is ApiException) {
        message = apiError.message;
      }
      state = AuthSession(isLoading: false, error: message);
      return false;
    } catch (_) {
      state = AuthSession(isLoading: false, error: 'Login failed');
      return false;
    }
  }

  Future<void> logout() async {
    await clearToken();
    state = AuthSession();
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession>((ref) {
  return AuthSessionNotifier(ref);
});