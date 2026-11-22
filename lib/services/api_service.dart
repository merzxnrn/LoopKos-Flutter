import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ApiService {
  static Map<String, String> _headers([String? token]) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppConstants.publicAnonKey}',
    };
    if (token != null && token.isNotEmpty) {
      h['X-User-Token'] = token;
    }
    return h;
  }

  static Future<Map<String, dynamic>> _req(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppConstants.serverUrl}$path');
    final headers = _headers(token);
    late http.Response res;

    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: headers);
        break;
      case 'POST':
        res = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        break;
      case 'PUT':
        res = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported method $method');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'HTTP ${res.statusCode}');
    }
    return data;
  }

  // Auth / Profile
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required String campus,
    String? phone,
  }) {
    return _req('POST', '/auth/register', body: {
      'email': email,
      'password': password,
      'name': name,
      'campus': campus,
      'phone': (phone != null && phone.isNotEmpty) ? phone : null,
    });
  }

  static Future<Map<String, dynamic>> getProfile(String token) {
    return _req('GET', '/profile', token: token);
  }

  static Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> updates) {
    return _req('PUT', '/profile', token: token, body: updates);
  }

  // Products
  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    String? search,
    String? sellerId,
  }) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sellerId != null && sellerId.isNotEmpty) params['sellerId'] = sellerId;

    final query = Uri(queryParameters: params).query;
    final path = query.isNotEmpty ? '/products?$query' : '/products';
    final data = await _req('GET', path);
    return List<Map<String, dynamic>>.from(data['products'] ?? []);
  }

  static Future<Map<String, dynamic>> getProduct(String id) async {
    final data = await _req('GET', '/products/$id');
    return Map<String, dynamic>.from(data['product']);
  }

  static Future<Map<String, dynamic>> createProduct(String token, Map<String, dynamic> payload) async {
    final data = await _req('POST', '/products', token: token, body: payload);
    return Map<String, dynamic>.from(data['product']);
  }

  static Future<void> deleteProduct(String token, String id) async {
    await _req('DELETE', '/products/$id', token: token);
  }

  // Bundles
  static Future<List<Map<String, dynamic>>> getBundles() async {
    final data = await _req('GET', '/bundles');
    return List<Map<String, dynamic>>.from(data['bundles'] ?? []);
  }

  static Future<Map<String, dynamic>> createBundle(String token, Map<String, dynamic> payload) async {
    final data = await _req('POST', '/bundles', token: token, body: payload);
    return Map<String, dynamic>.from(data['bundle']);
  }

  // Transactions
  static Future<List<Map<String, dynamic>>> getTransactions(String token, {String role = 'buyer'}) async {
    final data = await _req('GET', '/transactions?role=$role', token: token);
    return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
  }

  static Future<Map<String, dynamic>> createTransaction(String token, Map<String, dynamic> payload) async {
    final data = await _req('POST', '/transactions', token: token, body: payload);
    return Map<String, dynamic>.from(data['transaction']);
  }

  static Future<Map<String, dynamic>> updateTransaction(String token, String id, Map<String, dynamic> payload) async {
    final data = await _req('PUT', '/transactions/$id', token: token, body: payload);
    return Map<String, dynamic>.from(data['transaction']);
  }

  // Upload
  static Future<Map<String, dynamic>> uploadFile(String token, File file, {String bucket = 'images'}) async {
    final uri = Uri.parse('${AppConstants.serverUrl}/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${AppConstants.publicAnonKey}'
      ..headers['X-User-Token'] = token
      ..fields['bucket'] = bucket
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Upload gagal');
    }
    return data;
  }
}
