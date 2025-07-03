import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/models/product.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  double _buyPrice = 0.0;
  double _sellPrice = 0.0;
  int _stock = 0;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _buyPriceController.text = widget.product!.buyPrice.toString();
      _sellPriceController.text = widget.product!.sellPrice.toString();
      _stockController.text = widget.product!.stock.toString();
      _buyPrice = widget.product!.buyPrice;
      _sellPrice = widget.product!.sellPrice;
      _stock = widget.product!.stock;
    }
    
    // Add listeners for real-time calculation
    _buyPriceController.addListener(_calculateProfit);
    _sellPriceController.addListener(_calculateProfit);
    _stockController.addListener(_calculateProfit);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _calculateProfit() {
    if (_isCalculating) return;
    _isCalculating = true;
    
    setState(() {
      _buyPrice = double.tryParse(_buyPriceController.text) ?? 0.0;
      _sellPrice = double.tryParse(_sellPriceController.text) ?? 0.0;
      _stock = int.tryParse(_stockController.text) ?? 0;
    });
    
    _isCalculating = false;
  }

  double get _profit => _sellPrice - _buyPrice;
  double get _profitPercentage => _buyPrice > 0 ? (_profit / _buyPrice) * 100 : 0;
  double get _totalValue => _stock * _sellPrice;
  double get _totalProfit => _stock * _profit;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final productVM = context.read<ProductViewModel>();
    final userId = context.read<AuthViewModel>().user?.id;
    if (userId == null) return;

    try {
      if (widget.product == null) {
        // Create new product
        await productVM.createProduct(
          userId: userId,
          name: _nameController.text.trim(),
          buyPrice: _buyPrice,
          sellPrice: _sellPrice,
          stock: _stock,
        );
      } else {
        // Update existing product
        final updatedProduct = widget.product!.copyWith(
          name: _nameController.text.trim(),
          buyPrice: _buyPrice,
          sellPrice: _sellPrice,
          stock: _stock,
        );
        await productVM.updateProduct(updatedProduct, userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null 
                ? 'Product added successfully!' 
                : 'Product updated successfully!'
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.product == null ? Icons.add_box : Icons.edit,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product == null ? 'Add New Product' : 'Edit Product',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 4),
                Text(
                  widget.product == null
                      ? 'Create a new product in your inventory'
                      : 'Update product information',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Profit Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProfitItem(
                  'Unit Profit',
                  '${_profit.toStringAsFixed(2)} DZD',
                  _profit >= 0 ? Colors.green : Colors.red,
                  Icons.trending_up,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildProfitItem(
                  'Profit %',
                  '${_profitPercentage.toStringAsFixed(1)}%',
                  _profit >= 0 ? Colors.green : Colors.red,
                  Icons.percent,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProfitItem(
                  'Total Value',
                  '${_totalValue.toStringAsFixed(2)} DZD',
                  Colors.blue,
                  Icons.attach_money,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildProfitItem(
                  'Total Profit',
                  '${_totalProfit.toStringAsFixed(2)} DZD',
                  _totalProfit >= 0 ? Colors.green : Colors.red,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitItem(String title, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines,
    bool isMobile = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines ?? 1,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixText: prefixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 12 : 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.product == null ? 'Add Product' : 'Edit Product',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Consumer<ProductViewModel>(
            builder: (context, productVM, child) {
              if (productVM.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Saving product...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 600,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(isMobile ? 20 : 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
                            ),
                            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                                ),
                                child: Icon(
                                  Icons.inventory,
                                  color: Colors.blue,
                                  size: isMobile ? 24 : 32,
                                ),
                              ),
                              SizedBox(width: isMobile ? 16 : 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product == null ? 'Add New Product' : 'Edit Product',
                                      style: TextStyle(
                                        fontSize: isMobile ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      widget.product == null 
                                          ? 'Create a new product for your inventory'
                                          : 'Update product information',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 24 : 32),

                        // Form Fields
                        _buildFormField(
                          controller: _nameController,
                          label: 'Product Name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter product name';
                            }
                            return null;
                          },
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: _buyPriceController,
                                label: 'Buy Price (DZD)',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter buy price';
                                  }
                                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                    return 'Please enter a valid price';
                                  }
                                  return null;
                                },
                                isMobile: isMobile,
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: _buildFormField(
                                controller: _sellPriceController,
                                label: 'Sell Price (DZD)',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter sell price';
                                  }
                                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                    return 'Please enter a valid price';
                                  }
                                  return null;
                                },
                                isMobile: isMobile,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: _stockController,
                                label: 'Initial Stock',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter stock quantity';
                                  }
                                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                                    return 'Please enter a valid quantity';
                                  }
                                  return null;
                                },
                                isMobile: isMobile,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 24 : 32),

                        // Error Display
                        if (productVM.error != null)
                          Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: isMobile ? 16 : 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    productVM.error!,
                                    style: TextStyle(
                                      color: Colors.red, 
                                      fontSize: isMobile ? 12 : 14
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 16)),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: isMobile ? 16 : 18),
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: productVM.isLoading ? null : _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 16)),
                                ),
                                child: productVM.isLoading
                                    ? SizedBox(
                                        height: isMobile ? 20 : 24,
                                        width: isMobile ? 20 : 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        widget.product == null ? 'Add Product' : 'Update Product',
                                        style: TextStyle(
                                          fontSize: isMobile ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
