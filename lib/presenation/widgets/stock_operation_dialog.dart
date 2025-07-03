import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/product.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/company_viewmodel.dart';

class StockItem {
  final Product product;
  int quantity;

  StockItem({required this.product, required this.quantity});
}

class StockOperationDialog extends StatefulWidget {
  final VoidCallback onOperationComplete;

  const StockOperationDialog({
    Key? key,
    required this.onOperationComplete,
  }) : super(key: key);

  @override
  State<StockOperationDialog> createState() => _StockOperationDialogState();
}

class _StockOperationDialogState extends State<StockOperationDialog> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  List<StockItem> _stockItems = [];
  String _operationType = 'in';
  bool _isExecuting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- BEGIN: Paste all methods and widget builders from the previous _StockOperationDialogState here ---
  // (build method, _showClientInfoDialog, _executeStockOperation, _removeFromStockList, _updateQuantity, _addToStockList, _buildMainContent, _buildContentColumn, _buildHeader, _buildOperationTypeSelector, _buildSearchBar, _buildProductsList, _buildSelectedProductsSection, _buildActionButtons, _buildOperationTypeCard, _showQuantityBottomSheet, etc.)
  // --- END ---
} 