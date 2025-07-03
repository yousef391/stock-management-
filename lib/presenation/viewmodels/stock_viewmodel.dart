import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/models/stock_performa.dart';
import '../../data/repo/stock_repository.dart';
import '../screens/stock_screen.dart'; // Import for StockItem

class StockViewModel extends ChangeNotifier {
  final StockRepository _repository;
  List<Product> _products = [];
  List<StockPerforma> _performas = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<StockPerforma> get performas => _performas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StockViewModel(this._repository);

  Future<void> fetchProducts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _repository.fetchProducts(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPerformas(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _performas = await _repository.fetchPerformas(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> stockIn({
    required Product product,
    required int quantity,
    required String userId,
    required companyInfo,
  }) async {
    await _updateStock(
      product: product,
      quantity: quantity,
      type: 'in',
      userId: userId,
      companyInfo: companyInfo,
    );
  }

  Future<void> stockOut({
    required Product product,
    required int quantity,
    required String userId,
    required companyInfo,
  }) async {
    await _updateStock(
      product: product,
      quantity: quantity,
      type: 'out',
      userId: userId,
      companyInfo: companyInfo,
    );
  }

  Future<void> _updateStock({
    required Product product,
    required int quantity,
    required String type, // 'in' or 'out'
    required String userId,
    required companyInfo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      int newStock =
          type == 'in' ? product.stock + quantity : product.stock - quantity;
      if (newStock < 0) {
        _error = 'Stock cannot be negative';
        _isLoading = false;
        notifyListeners();
        return;
      }
      await _repository.updateProductStock(
        productId: product.id,
        newStock: newStock,
      );
      final performaData = {
        'user_id': userId,
        'product_id': product.id,
        'product_name': product.name,
        'buy_price': product.buyPrice,
        'sell_price': product.sellPrice,
        'quantity': quantity,
        'type': type,
      };
      final performa = await _repository.createPerformaRecord(performaData);
      await _generateAndUploadPerforma(
        performa,
        product,
        type,
        companyInfo: companyInfo,
      );
      await fetchProducts(userId);
      await fetchPerformas(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _generateAndUploadPerforma(
    StockPerforma performa,
    dynamic items, // Can be Product or List<StockItem>
    String operationType, {
    required companyInfo,
    double deliveryCharge = 0,
  }) async {
    try {
      print(
        '_generateAndUploadPerforma: Generating PDF for performa: [performa.id]',
      );
      final pdfBytes = await _repository.generateStockPerformaPdf(
        performa: performa,
        items: items is List ? items : [items],
        performaNumber: performa.performaNumber,
        operationType: operationType,
        companyInfo: companyInfo,
        deliveryCharge: deliveryCharge,
      );
      print(
        '_generateAndUploadPerforma: Uploading PDF for performa: [performa.id]',
      );
      final pdfUrl = await _repository.uploadFacturePdf(
        pdfBytes,
        performa.performaNumber,
      );
      if (pdfUrl != null) {
        print(
          '_generateAndUploadPerforma: Updating performa pdfUrl for performa: [performa.id]',
        );
        await _repository.updatePerformaPdfUrl(
          performaId: performa.id,
          pdfUrl: pdfUrl,
        );
      } else {
        print(
          '_generateAndUploadPerforma: pdfUrl is null for performa: [performa.id]',
        );
      }
    } catch (e) {
      print('_generateAndUploadPerforma: Exception: $e');
      // Don't fail the stock operation if PDF generation fails
    }
  }

  Future<void> createPerformaWithMultipleProducts({
    required List<StockItem> items,
    required String operationType,
    required String userId,
    required companyInfo,
    String? recipientName,
    String? recipientCompany,
    String? recipientAddress,
    String? recipientPhone,
    double deliveryCharge = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Validate all stock operations
      for (final item in items) {
        if (operationType == 'out' && item.quantity > item.product.stock) {
          _error =
              'Cannot remove 27${item.quantity}27 units from 27${item.product.name}27. Available stock: 27${item.product.stock}27';
          return;
        }
      }
      // Update all product stocks
      for (final item in items) {
        int newStock =
            operationType == 'in'
                ? item.product.stock + item.quantity
                : item.product.stock - item.quantity;
        if (newStock < 0) {
          _error = 'Stock cannot be negative for ${item.product.name}';
          return;
        }
        await _repository.updateProductStock(
          productId: item.product.id,
          newStock: newStock,
        );
      }
      // Create performa items list
      final performaItems =
          items
              .map(
                (item) => {
                  'product_id': item.product.id,
                  'product_name': item.product.name,
                  'buy_price': item.product.buyPrice,
                  'sell_price': item.product.sellPrice,
                  'quantity': item.quantity,
                  'current_stock': item.product.stock,
                },
              )
              .toList();
      final performaNumber = await _generateUniquePerformaNumber(userId);
      final performaData = {
        'user_id': userId,
        'type': operationType,
        'items': performaItems,
        'performa_number': performaNumber,
        'recipient_name': recipientName,
        'recipient_company': recipientCompany,
        'recipient_address': recipientAddress,
        'recipient_phone': recipientPhone,
      };
      StockPerforma? performa;
      int retryCount = 0;
      const maxRetries = 3;
      while (retryCount < maxRetries) {
        try {
          performa = await _repository.createPerformaRecord(performaData);
          break;
        } catch (e) {
          retryCount++;
          if (e.toString().contains(
                'duplicate key value violates unique constraint',
              ) &&
              retryCount < maxRetries) {
            performaData['performa_number'] =
                await _generateUniquePerformaNumber(userId);
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
            continue;
          } else {
            rethrow;
          }
        }
      }
      if (performa == null) {
        throw Exception('Failed to create performa after $maxRetries attempts');
      }
      try {
        await _generateAndUploadPerforma(
          performa,
          items,
          operationType,
          companyInfo: companyInfo,
          deliveryCharge: deliveryCharge,
        );
      } catch (e) {
        // Don't fail the operation if PDF generation fails
      }
      await fetchProducts(userId);
      await fetchPerformas(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String> _generateUniquePerformaNumber(String userId) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final millisStr = now.millisecondsSinceEpoch.toString().substring(
      8,
    ); // Last 4 digits
    return 'PERF-$dateStr-$timeStr-$millisStr';
  }

  Future<void> testSimpleStockOut({
    required Product product,
    required int quantity,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (quantity > product.stock) {
        _error =
            'Cannot remove $quantity units. Available stock: ${product.stock}';
        return;
      }
      int newStock = product.stock - quantity;
      await _repository.updateProductStock(
        productId: product.id,
        newStock: newStock,
      );
      await fetchProducts(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // Add this public method to allow UI to trigger PDF generation for a performa
  Future<void> generateAndUploadPerformaPdf({
    required StockPerforma performa,
    required List items,
    required String performaNumber,
    required String operationType,
    required companyInfo,
    double deliveryCharge = 0,
  }) async {
    print('generateAndUploadPerformaPdf called for performa: ${performa.id}');
    // Fix: Map PerformaItem to expected structure for PDF generation
    final mappedItems =
        items.map((item) {
          if (item is PerformaItem) {
            return _PerformaItemAdapter(item);
          }
          return item;
        }).toList();
    await _generateAndUploadPerforma(
      performa,
      mappedItems,
      operationType,
      companyInfo: companyInfo,
      deliveryCharge: deliveryCharge,
    );
    print('generateAndUploadPerformaPdf finished for performa: ${performa.id}');
  }

  Future<void> deletePerformaAndResetProducts(StockPerforma performa, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.deletePerformaAndResetProducts(performa, userId);
      await fetchProducts(userId);
      await fetchPerformas(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}

// Helper adapter class for PerformaItem to match expected interface
class _PerformaItemAdapter {
  final PerformaItem item;
  _PerformaItemAdapter(this.item);
  int get quantity => item.quantity;
  double get buyPrice => item.buyPrice;
  double get sellPrice => item.sellPrice;
  _ProductAdapter get product => _ProductAdapter(item);
}

class _ProductAdapter {
  final PerformaItem item;
  _ProductAdapter(this.item);
  String get name => item.productName;
  double get buyPrice => item.buyPrice;
  double get sellPrice => item.sellPrice;
}
