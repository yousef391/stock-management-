class StockLog {
  final String id;
  final String productId;
  final String userId;
  final int quantity;
  final String type; // 'in' or 'out'
  final String createdAt;

  StockLog({
    required this.id,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.type,
    required this.createdAt,
  });

  factory StockLog.fromJson(Map<String, dynamic> json) {
    return StockLog(
      id: json['id'],
      productId: json['product_id'],
      userId: json['user_id'],
      quantity: json['quantity'],
      type: json['type'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'quantity': quantity,
      'type': type,
      'created_at': createdAt,
    };
  }

  StockLog copyWith({
    String? id,
    String? productId,
    String? userId,
    int? quantity,
    String? type,
    String? createdAt,
  }) {
    return StockLog(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
