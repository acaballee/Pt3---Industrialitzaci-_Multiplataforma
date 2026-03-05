class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String? userId;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.userId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': name,
      'description': description,
      'price': price,
    };
    if (userId != null) {
      data['user_id'] = userId;
    }
    return data;
  }
}
