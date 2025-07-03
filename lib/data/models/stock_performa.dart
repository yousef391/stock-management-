class StockPerforma {
  final String id;
  final String userId;
  final String performaNumber;
  final String type; // 'in' or 'out'
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PerformaItem> items; // List of products in this performa
  // Recipient/client/supplier info
  final String? recipientName;
  final String? recipientCompany;
  final String? recipientAddress;
  final String? recipientPhone;

  StockPerforma({
    required this.id,
    required this.userId,
    required this.performaNumber,
    required this.type,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.recipientName,
    this.recipientCompany,
    this.recipientAddress,
    this.recipientPhone,
  });

  factory StockPerforma.fromJson(Map<String, dynamic> json) {
    return StockPerforma(
      id: json['id'],
      userId: json['user_id'],
      performaNumber: json['performa_number'],
      type: json['type'],
      pdfUrl: json['pdf_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => PerformaItem.fromJson(item)).toList()
          : [],
      recipientName: json['recipient_name'],
      recipientCompany: json['recipient_company'],
      recipientAddress: json['recipient_address'],
      recipientPhone: json['recipient_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'performa_number': performaNumber,
      'type': type,
      'pdf_url': pdfUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'recipient_name': recipientName,
      'recipient_company': recipientCompany,
      'recipient_address': recipientAddress,
      'recipient_phone': recipientPhone,
    };
  }

  StockPerforma copyWith({
    String? id,
    String? userId,
    String? performaNumber,
    String? type,
    String? pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PerformaItem>? items,
    String? recipientName,
    String? recipientCompany,
    String? recipientAddress,
    String? recipientPhone,
  }) {
    return StockPerforma(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      performaNumber: performaNumber ?? this.performaNumber,
      type: type ?? this.type,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      recipientName: recipientName ?? this.recipientName,
      recipientCompany: recipientCompany ?? this.recipientCompany,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      recipientPhone: recipientPhone ?? this.recipientPhone,
    );
  }
}

class PerformaItem {
  final String productId;
  final String productName;
  final double buyPrice;
  final double sellPrice;
  final int quantity;
  final int currentStock;

  PerformaItem({
    required this.productId,
    required this.productName,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.currentStock,
  });

  factory PerformaItem.fromJson(Map<String, dynamic> json) {
    return PerformaItem(
      productId: json['product_id'],
      productName: json['product_name'],
      buyPrice: (json['buy_price'] as num).toDouble(),
      sellPrice: (json['sell_price'] as num).toDouble(),
      quantity: json['quantity'],
      currentStock: json['current_stock'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'quantity': quantity,
      'current_stock': currentStock,
    };
  }
} 