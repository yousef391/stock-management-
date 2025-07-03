import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/data/models/product.dart';
import 'package:stock_management/presenation/screens/stock_screen.dart';
import 'package:stock_management/presenation/viewmodels/auth_viewmodel.dart';
import 'package:stock_management/presenation/viewmodels/company_viewmodel.dart';
import 'package:stock_management/presenation/viewmodels/stock_viewmodel.dart';

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

  void _showClientInfoDialog() {
    final nameController = TextEditingController();
    final companyController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.person, color: Colors.indigo, size: 24),
                SizedBox(width: 12),
                Text(_operationType == 'out' ? 'Invoice To (Client Info)' : 'Invoice From (Supplier Info)' , style: TextStyle(fontSize: 14),),
              ],
            ),
            content: SizedBox(
              width: isMobile ? 260 : 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: companyController,
                      decoration: InputDecoration(
                        labelText: 'Company/Business',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Back'),
              ),
              ElevatedButton(
                onPressed: _isExecuting
                    ? null
                    : () async {
                        await _executeStockOperation(
                          recipientName: nameController.text.trim(),
                          recipientCompany: companyController.text.trim(),
                          recipientAddress: addressController.text.trim(),
                          recipientPhone: phoneController.text.trim(),
                        );
                      },
                child: _isExecuting
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Confirm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _executeStockOperation({
    String? recipientName,
    String? recipientCompany,
    String? recipientAddress,
    String? recipientPhone,
  }) async {
    if (_stockItems.isEmpty) return;
    setState(() {
      _isExecuting = true;
    });
    final stockVM = context.read<StockViewModel>();
    final userId = context.read<AuthViewModel>().user?.id;
    try {
      if (userId != null) {
        await stockVM.fetchProducts(userId);
      }
      List<StockItem> updatedStockItems = [];
      for (final item in _stockItems) {
        final updatedProduct = stockVM.products.firstWhere(
          (p) => p.id == item.product.id,
          orElse: () => item.product,
        );
        if (_operationType == 'out' && item.quantity > updatedProduct.stock) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot remove ${item.quantity} units from ${item.product.name}. Available stock: ${updatedProduct.stock}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
        updatedStockItems.add(StockItem(
          product: updatedProduct,
          quantity: item.quantity,
        ));
      }
      await stockVM.createPerformaWithMultipleProducts(
        items: updatedStockItems,
        operationType: _operationType,
        userId: userId!,
        companyInfo: context.read<CompanyViewModel>().companyInfo,
        recipientName: recipientName,
        recipientCompany: recipientCompany,
        recipientAddress: recipientAddress,
        recipientPhone: recipientPhone,
      );
      if (stockVM.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${stockVM.error}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock ${_operationType == 'in' ? 'In' : 'Out'} operation completed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.of(context).pop(); // Close client info dialog
        Navigator.of(context).pop(); // Close main stock operation dialog
        widget.onOperationComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    }
  }

  void _removeFromStockList(int index) {
    setState(() {
      _stockItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    final item = _stockItems[index];
    final isStockOut = _operationType == 'out';
    final maxQuantity = isStockOut ? item.product.stock : 999999;
    if (newQuantity > 0 && newQuantity <= maxQuantity) {
      setState(() {
        _stockItems[index].quantity = newQuantity;
      });
    } else if (newQuantity > maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantity cannot exceed ${isStockOut ? 'current stock' : 'maximum limit'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addToStockList(Product product, int quantity) {
    final existingIndex = _stockItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      setState(() {
        _stockItems[existingIndex].quantity += quantity;
      });
    } else {
      setState(() {
        _stockItems.add(StockItem(
          product: product,
          quantity: quantity,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('StockOperationDialog: build started');
    final isMobile = MediaQuery.of(context).size.width < 600;
    try {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width * 0.99 : MediaQuery.of(context).size.width * 0.95,
          height: isMobile ? MediaQuery.of(context).size.height * 0.99 : MediaQuery.of(context).size.height * 0.9,
          padding: EdgeInsets.all(isMobile ? 8 : 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildMainContent(isMobile),
          ),
        ),
      );
    } catch (e, stack) {
      print('StockOperationDialog: build failed: ' + e.toString());
      print(stack);
      return Dialog(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Dialog build failed: ${e.toString()}',
              style: TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMainContent(bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        child: _buildContentColumn(),
      );
    } else {
      // Desktop/Tablet layout - using Row for better space utilization
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel - Products and Search
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 16),
                _buildOperationTypeSelector(),
                SizedBox(height: 16),
                _buildSearchBar(),
                SizedBox(height: 16),
                Expanded(child: _buildProductsList()),
              ],
            ),
          ),
          SizedBox(width: 24),
          // Right panel - Selected items and actions
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSelectedProductsSection(),
                SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildContentColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 12),
        _buildOperationTypeSelector(),
        SizedBox(height: 12),
        _buildSearchBar(),
        SizedBox(height: 12),
        _buildProductsList(),
        SizedBox(height: 12),
        _buildSelectedProductsSection(),
        SizedBox(height: 16),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _operationType == 'in'
                  ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)]
                  : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _operationType == 'in' ? Icons.arrow_downward : Icons.arrow_upward,
            color: _operationType == 'in' ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Stock Operation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                'Add products to your ${_operationType == 'in' ? 'stock in' : 'stock out'} operation',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationTypeSelector() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOperationTypeCard(
              'in',
              'Stock In',
              'Add products',
              Icons.arrow_downward,
              Colors.green,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildOperationTypeCard(
              'out',
              'Stock Out',
              'Remove products',
              Icons.arrow_upward,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.blue, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, child) {
        if (stockVM.isLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final filteredProducts = _searchText.isEmpty
            ? stockVM.products
            : stockVM.products.where((p) => p.name.toLowerCase().contains(_searchText)).toList();
        final isMobile = MediaQuery.of(context).size.width < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Products (${filteredProducts.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 6),
            filteredProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('No products found', style: TextStyle(color: Colors.grey[600])),
                    ),
                  )
                : (isMobile
                    ? SizedBox(
                        height: 220,
                        child: ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isLowStock = product.stock <= 5;
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(product.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text('Stock: ${product.stock} | Buy: ${product.buyPrice.toStringAsFixed(2)} DZD | Sell: ${product.sellPrice.toStringAsFixed(2)} DZD', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _operationType == 'in' ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(_operationType == 'in' ? 'Add' : 'Remove', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                onTap: () => _showQuantityBottomSheet(product),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        constraints: BoxConstraints(maxHeight: 320),
                        child: ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isLowStock = product.stock <= 5;
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(product.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text('Stock: ${product.stock} | Buy: ${product.buyPrice.toStringAsFixed(2)} DZD | Sell: ${product.sellPrice.toStringAsFixed(2)} DZD', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _operationType == 'in' ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(_operationType == 'in' ? 'Add' : 'Remove', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                onTap: () => _showQuantityBottomSheet(product),
                              ),
                            );
                          },
                        ),
                      )
                  ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selected Products (${_stockItems.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 6),
        _stockItems.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No products selected', style: TextStyle(color: Colors.grey[600])),
                ),
              )
            : Column(
                children: _stockItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(item.product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Qty: ${item.quantity} | Stock: ${item.product.stock}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, size: 18),
                            onPressed: () {
                              if (item.quantity > 1) _updateQuantity(index, item.quantity - 1);
                            },
                          ),
                          Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          IconButton(
                            icon: Icon(Icons.add, size: 18),
                            onPressed: () => _updateQuantity(index, item.quantity + 1),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => _removeFromStockList(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close),
            label: Text('Cancel'),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _stockItems.isNotEmpty && !_isExecuting ? _showClientInfoDialog : null,
            icon: Icon(Icons.navigate_next),
            label: Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationTypeCard(String type, String title, String description, IconData icon, Color color) {
    final isSelected = _operationType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _operationType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? color : Colors.grey[600],
                    size: 18,
                  ),
                ),
                Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 18,
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[800],
                fontSize: 13,
              ),
            ),
            SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantityBottomSheet(Product product) {
    final quantityController = TextEditingController();
    final isStockOut = _operationType == 'out';
    final maxQuantity = isStockOut ? product.stock : 999999;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_operationType == 'in' ? Icons.arrow_downward : Icons.arrow_upward, color: _operationType == 'in' ? Colors.green : Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set Quantity',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(product.name, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Enter quantity',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.shopping_cart),
                    suffixText: isStockOut ? 'Max: $maxQuantity' : null,
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final quantity = int.tryParse(quantityController.text) ?? 0;
                          if (quantity > 0 && quantity <= maxQuantity) {
                            _addToStockList(product, quantity);
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isStockOut
                                    ? 'Quantity cannot exceed current stock ($maxQuantity)'
                                    : 'Please enter a valid quantity'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(_operationType == 'in' ? 'Add' : 'Remove'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _operationType == 'in' ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    });
  }
}