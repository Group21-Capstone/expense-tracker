import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User _mapUser(dynamic supaUser) {
    final metadata = supaUser.userMetadata ?? <String, dynamic>{};
    return User(
      id: supaUser.id,
      name: (metadata['name'] ?? '') as String,
      email: supaUser.email ?? '',
    );
  }

  Future<User> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final supaUser = response.user;
    if (supaUser == null) {
      throw Exception('Invalid credentials');
    }
    return _mapUser(supaUser);
  }

  Future<User> register(String name, String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    final supaUser = response.user;
    if (supaUser == null) {
      throw Exception('Registration failed');
    }
    // If email confirmation is enabled in Supabase, no session exists yet.
    // Disable "Confirm email" in Supabase Auth settings for the demo flow.
    return _mapUser(supaUser);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<User?> getUser() async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return null;
    return _mapUser(supaUser);
  }
}
