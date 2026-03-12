import 'package:flutter_test/flutter_test.dart';
import 'package:first_flutter/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Product constructor works correctly', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        description: 'Test Description',
        price: 99.99,
        userId: 'user123',
      );

      expect(product.id, 1);
      expect(product.name, 'Test Product');
      expect(product.description, 'Test Description');
      expect(product.price, 99.99);
      expect(product.userId, 'user123');
    });

    test('Product.fromJson creates accurate Product object', () {
      final json = {
        'id': 1,
        'title': 'Test Product',
        'description': 'Test Description',
        'price': 99.99,
        'user_id': 'user123',
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.name, 'Test Product');
      expect(product.description, 'Test Description');
      expect(product.price, 99.99);
      expect(product.userId, 'user123');
    });

    test('Product.toJson returns accurate Map', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        description: 'Test Description',
        price: 99.99,
        userId: 'user123',
      );

      final json = product.toJson();

      expect(json['title'], 'Test Product');
      expect(json['description'], 'Test Description');
      expect(json['price'], 99.99);
      expect(json['user_id'], 'user123');
      expect(
        json.containsKey('id'),
        isFalse,
      ); 
    });

    test('Product.toJson handles null userId', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        description: 'Test Description',
        price: 99.99,
        userId: null,
      );

      final json = product.toJson();

      expect(json['title'], 'Test Product');
      expect(json['description'], 'Test Description');
      expect(json['price'], 99.99);
      expect(json.containsKey('user_id'), isFalse);
    });
  });
}
