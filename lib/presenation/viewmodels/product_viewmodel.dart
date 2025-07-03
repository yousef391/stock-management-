import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repo/product_repository.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductRepository _repository;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductViewModel(this._repository);

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

  Future<void> createProduct({
    required String userId,
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int stock,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.createProduct(
        userId: userId,
        name: name,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
      );
      await fetchProducts(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProduct(Product product, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.updateProduct(product);
      await fetchProducts(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteProduct(String productId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.deleteProduct(productId);
      await fetchProducts(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
} 