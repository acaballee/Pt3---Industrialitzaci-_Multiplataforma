import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://itvyvvxonnsdoqokvikw.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0dnl2dnhvbm5zZG9xb2t2aWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODE1NTQsImV4cCI6MjA4MTA1NzU1NH0.6AxDj1flnnqtBvOjoKe9_MehqBwo0kNgxLGOf4VKQ5A';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
  };

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/v1/token?grant_type=password');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Login correcte
        return jsonDecode(response.body);
      } else {
        // Error (credencials incorrectes, etc.)
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error_description'] ?? 'Error desconegut al login',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> getProducts() async {
    final url = Uri.parse('$_baseUrl/rest/v1/products?select=*');
    return await http.get(url, headers: _headers);
  }

  Future<void> createProduct(
    String token,
    Map<String, dynamic> productData,
  ) async {
    final url = Uri.parse('$_baseUrl/rest/v1/products');

    final customHeaders = {
      'Content-Type': 'application/json',
      'apikey': _anonKey,
      'Authorization': 'Bearer $token',
      'Prefer': 'return=representation',
      'Accept': 'application/vnd.pgrst.object+json',
    };

    final response = await http.post(
      url,
      headers: customHeaders,
      body: jsonEncode(productData),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error creating product: ${response.body}');
    }
  }

  Future<http.Response> getUserProducts(String token, String userId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/products?select=*&user_id=eq.$userId',
    );
    final headers = {
      'Content-Type': 'application/json',
      'apikey': _anonKey,
      'Authorization': 'Bearer $token',
    };

    return await http.get(url, headers: headers);
  }
}
