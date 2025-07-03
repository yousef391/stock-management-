import 'package:flutter/material.dart';
import '../../data/repo/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseAuthRepository _authRepository = SupabaseAuthRepository();
  User? _user;
  String? _error;
  bool _isLoading = false;

  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;

  AuthViewModel() {
    _user = _authRepository.getCurrentUser();
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _authRepository.signIn(email: email, password: password);
      _user = response.user;
      if (_user == null) {
        _error = 'Invalid credentials';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _authRepository.signUp(email: email, password: password);
      _user = response.user;
      if (_user == null) {
        _error = 'Sign up failed';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUpAndCreateProfile(String email, String password, String fullName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _authRepository.signUp(email: email, password: password);
      _user = response.user;
      if (_user != null) {
        
        await Supabase.instance.client.from('users').insert({
          'id': _user!.id,
          'full_name': fullName,
          'role': 'staff',
        });
      } else {
        _error = 'Sign up failed';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _user = null;
    notifyListeners();
  }
} 