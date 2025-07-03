class Product {
  final String id;
  final String userId;
  final String name;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.createdAt,
  });

  // Calculated properties for profit analysis
  double get profit => sellPrice - buyPrice;
  double get profitPercentage => buyPrice > 0 ? (profit / buyPrice) * 100 : 0;
  String get formattedProfit => '${profit.toStringAsFixed(2)} DZD';
  String get formattedProfitPercentage => '${profitPercentage.toStringAsFixed(1)}%';

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      buyPrice: (map['buy_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock': stock,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? userId,
    String? name,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
