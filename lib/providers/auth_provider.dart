import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  String? _accessToken;
  bool _isLoading = true;
  bool _fetchingProfile = false;
  StreamSubscription<AuthState>? _authSub;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  void _init() {
    final supabase = Supabase.instance.client;
    _handleSession(supabase.auth.currentSession);

    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      _handleSession(data.session);
    });
  }

  Future<void> _handleSession(Session? session) async {
    if (session != null && session.accessToken.isNotEmpty) {
      if (_fetchingProfile) return;
      _fetchingProfile = true;
      _accessToken = session.accessToken;
      try {
        final data = await ApiService.getProfile(session.accessToken);
        _user = AuthUser.fromJson(Map<String, dynamic>.from(data['profile']));
      } catch (_) {
        final meta = session.user.userMetadata ?? {};
        _user = AuthUser(
          id: session.user.id,
          email: session.user.email ?? '',
          name: (meta['name'] ?? session.user.email?.split('@').first ?? 'User').toString(),
          campus: (meta['campus'] ?? '').toString(),
          phone: meta['phone']?.toString(),
          verified: session.user.emailConfirmedAt != null,
          rating: 5.0,
          totalSales: 0,
          totalPurchases: 0,
          joinedAt: session.user.createdAt,
        );
      } finally {
        _isLoading = false;
        _fetchingProfile = false;
        notifyListeners();
      }
    } else {
      _user = null;
      _accessToken = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String campus,
    String? phone,
  }) async {
    if (name.trim().isEmpty) return 'Nama lengkap harus diisi.';
    if (password.length < 8) return 'Password minimal 8 karakter.';

    try {
      await ApiService.registerUser(
        email: email.trim(),
        password: password,
        name: name.trim(),
        campus: campus,
        phone: phone?.trim(),
      );

      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.session == null) {
        return 'Akun dibuat, tapi login gagal.';
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return 'Email atau password salah. Coba lagi.';
      }
      if (e.message.contains('Email not confirmed')) {
        return 'Email belum dikonfirmasi. Cek inbox kamu.';
      }
      return e.message;
    } catch (e) {
      return 'Kesalahan jaringan: $e';
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<String?> updateProfile(Map<String, dynamic> updates) async {
    if (_accessToken == null) return 'Tidak ada sesi aktif.';
    try {
      final data = await ApiService.updateProfile(_accessToken!, updates);
      if (data['profile'] != null) {
        _user = AuthUser.fromJson(Map<String, dynamic>.from(data['profile']));
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
