import 'dart:convert';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductRepository {
  final ApiService apiService;

  ProductRepository({required this.apiService});

  String? _accessToken;
  Map<String, dynamic>? _userData;

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get userData => _userData;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiService.login(email, password);
    _accessToken = response['access_token'];
    _userData = response['user'];
    return response;
  }

  Future<List<Product>> getProducts() async {
    final response = await apiService.getProducts();
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  Future<void> createProduct(Product product) async {
    if (_accessToken == null) {
      throw Exception('User not authenticated');
    }
    await apiService.createProduct(_accessToken!, product.toJson());
  }

  Future<List<Product>> getUserProducts() async {
    if (_accessToken == null || _userData == null || _userData!['id'] == null) {
      throw Exception('User authentication data missing');
    }

    final userId = _userData!['id'];
    final response = await apiService.getUserProducts(_accessToken!, userId);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load user products: ${response.body}');
    }
  }

  void logout() {
    _accessToken = null;
    _userData = null;
  }
}
