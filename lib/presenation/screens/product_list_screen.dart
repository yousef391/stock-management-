import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_viewmodel.dart';
import '../../data/models/product.dart';
import 'product_form_screen.dart';
import '../viewmodels/auth_viewmodel.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().user?.id;
      if (userId != null) {
        context.read<ProductViewModel>().fetchProducts(userId);
      }
    });
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Delete Product'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${product.name}"?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final userId = context.read<AuthViewModel>().user?.id;
              if (userId != null) {
                context.read<ProductViewModel>().deleteProduct(product.id, userId);
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
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
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 20),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildProductCard(Product product, bool isMobile) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      // Responsive parameters
      double padding = isMobile ? 16 : 28;
      double iconSize = isMobile ? 20 : 32;
      double fontSizeTitle = isMobile ? 16 : 22;
      double fontSizeId = isMobile ? 11 : 15;
      double fontSizeChip = isMobile ? 10 : 14;
      double fontSizeProfit = isMobile ? 10 : 14;
      double chipPaddingH = isMobile ? 10 : 16;
      double chipPaddingV = isMobile ? 5 : 10;
      int maxLinesTitle = isMobile ? 2 : 1;
      int maxLinesId = 1;
      double spacing = isMobile ? 10 : 18;
      double popupIconSize = isMobile ? 20 : 28;
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 0, // Grid already has spacing
          vertical: isMobile ? 6 : 0,
        ),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductFormScreen(product: product),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconSize / 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: Theme.of(context).primaryColor,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: fontSizeTitle,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: maxLinesTitle,
                              softWrap: false,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ID: ${product.id.substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: fontSizeId,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: maxLinesId,
                              softWrap: false,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[600],
                          size: popupIconSize,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductFormScreen(product: product),
                                ),
                              );
                              break;
                            case 'delete':
                              _showDeleteDialog(context, product);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: fontSizeTitle),
                                SizedBox(width: 8),
                                Text('Edit', overflow: TextOverflow.ellipsis, maxLines: 1),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: fontSizeTitle),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red), overflow: TextOverflow.ellipsis, maxLines: 1),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  // Info chips: Always in a Row, regardless of screen size
                  Row(
                    children: [
                      Flexible(
                        child: _buildInfoChip(
                          'Stock',
                          '${product.stock}',
                          product.stock > 0 ? Colors.green : Colors.red,
                          false,
                          fontSize: fontSizeChip,
                          paddingH: chipPaddingH,
                          paddingV: chipPaddingV,
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: _buildInfoChip(
                          'Buy Price',
                          '${product.buyPrice.toStringAsFixed(2)} DZD',
                          Colors.blue,
                          false,
                          fontSize: fontSizeChip,
                          paddingH: chipPaddingH,
                          paddingV: chipPaddingV,
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: _buildInfoChip(
                          'Sell Price',
                          '${product.sellPrice.toStringAsFixed(2)} DZD',
                          Colors.orange,
                          false,
                          fontSize: fontSizeChip,
                          paddingH: chipPaddingH,
                          paddingV: chipPaddingV,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  // Profit information (always on a new line)
                  _buildProfitContainer(product, isMobile,
                    fontSize: fontSizeProfit,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// Enhanced info chip with responsive design
Widget _buildInfoChip(String label, String value, Color color, bool isMobile, {double fontSize = 11, double paddingH = 10, double paddingV = 6}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: paddingH,
      vertical: paddingV,
    ),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize - 1,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// Enhanced profit container
Widget _buildProfitContainer(Product product, bool isMobile, {double fontSize = 11}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 12 : 14,
      vertical: isMobile ? 8 : 10,
    ),
    decoration: BoxDecoration(
      color: product.profit >= 0 
          ? Colors.green.withOpacity(0.1) 
          : Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: product.profit >= 0 
            ? Colors.green.withOpacity(0.3) 
            : Colors.red.withOpacity(0.3),
      ),
    ),
    child: Row(
      children: [
        Icon(
          product.profit >= 0 ? Icons.trending_up : Icons.trending_down,
          color: product.profit >= 0 ? Colors.green : Colors.red,
          size: fontSize + 3,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Profit: ${product.formattedProfit} (${product.formattedProfitPercentage})',
            style: TextStyle(
              color: product.profit >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

// Alternative: Using LayoutBuilder for even more precise responsive control
Widget _buildUltraResponsiveProductList(List<Product> products) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final isMobile = width < 600;
      
      if (isMobile) {
        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: products.length,
          itemBuilder: (context, index) => 
              _buildProductCard(products[index], true),
        );
      } else {
        // Calculate optimal grid parameters based on available width
        int crossAxisCount;
        double childAspectRatio;
        
        if (width > 1600) {
          crossAxisCount = 5;
          childAspectRatio = 2.4;
        } else if (width > 1200) {
          crossAxisCount = 4;
          childAspectRatio = 2.2;
        } else if (width > 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.8;
        } else if (width > 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.6;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 1.4;
        }
        
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => 
              _buildProductCard(products[index], false),
        );
      }
    },
  );
}

 

  Widget _buildSearchAndSortBar() {
    return Container(
      padding: EdgeInsets.all(16),
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
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
                items: [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'stock', child: Text('Stock')),
                  DropdownMenuItem(value: 'profit', child: Text('Profit')),
                  DropdownMenuItem(value: 'buyPrice', child: Text('Buy Price')),
                  DropdownMenuItem(value: 'sellPrice', child: Text('Sell Price')),
                ],
                underline: Container(),
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Product> _getFilteredAndSortedProducts(List<Product> products) {
    var filtered = products.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'stock':
          comparison = a.stock.compareTo(b.stock);
          break;
        case 'profit':
          comparison = a.profit.compareTo(b.profit);
          break;
        case 'buyPrice':
          comparison = a.buyPrice.compareTo(b.buyPrice);
          break;
        case 'sellPrice':
          comparison = a.sellPrice.compareTo(b.sellPrice);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildResponsiveStats(List<Widget> cards, bool isMobile) {
    if (isMobile) {
      return Column(
        children: cards
            .expand((card) => [card, SizedBox(height: 16)])
            .toList()
          ..removeLast(),
      );
    } else {
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: cards
            .map((card) => SizedBox(
                  width: 260,
                  child: card,
                ))
            .toList(),
      );
    }
  }

Widget _buildResponsiveProductList(List<Product> products, bool isMobile) {
  if (isMobile) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index], isMobile),
    );
  } else {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420, // Each card will be at most 420px wide
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.15, // Slightly taller than wide for good design
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index], false),
    );
  }
}

// Dynamic cross axis count based on screen width
int _getOptimalCrossAxisCount(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth > 1400) return 4;  // Extra large screens
  if (screenWidth > 1000) return 3;  // Large screens
  if (screenWidth > 700) return 2;   // Medium screens
  return 1; // Small desktop screens
}
double _getOptimalAspectRatio(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth > 1400) return 2.2;  // Extra large screens - more horizontal
  if (screenWidth > 1000) return 1.8;  // Large screens
  if (screenWidth > 700) return 1.6;   // Medium screens
  return 1.4; // Small desktop screens - more vertical
}

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        return Scaffold(
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
                        'Loading products...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (productVM.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error: ${productVM.error}',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final userId = context.read<AuthViewModel>().user?.id;
                          if (userId != null) {
                            productVM.fetchProducts(userId);
                          }
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredProducts = _getFilteredAndSortedProducts(productVM.products);
              final totalProducts = filteredProducts.length;
              final totalStockValue = filteredProducts.fold<double>(0, (sum, product) => sum + (product.stock * product.sellPrice));
              final lowStockProducts = filteredProducts.where((product) => product.stock <= 5).length;

              final statsCards = [
                _buildStatsCard('Total Products', '$totalProducts', Icons.inventory_2, Colors.blue),
                _buildStatsCard('Total Value', '${totalStockValue.toStringAsFixed(2)} DZD', Icons.attach_money, Colors.green),
                _buildStatsCard('Low Stock', '$lowStockProducts', Icons.warning, Colors.orange),
              ];

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 24 : 40),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 10 : isTablet ? 14 : 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.1)],
                                  ),
                                  borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 14 : 20),
                                ),
                                child: Icon(Icons.inventory, size: isMobile ? 22 : isTablet ? 28 : 36, color: Colors.blue),
                              ),
                              SizedBox(width: isMobile ? 10 : isTablet ? 14 : 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Products',
                                      style: TextStyle(
                                        fontSize: isMobile ? 22 : isTablet ? 28 : 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Text(
                                      'Manage your inventory products',
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : isTablet ? 15 : 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMobile) // Show button for desktop/tablet
                                Padding(
                                  padding: EdgeInsets.only(left: 16),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ProductFormScreen(),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.add),
                                    label: Text('Add Product'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      textStyle: TextStyle(fontSize: isTablet ? 16 : 18, fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 18 : isTablet ? 28 : 40),
                          // Statistics Cards
                          _buildResponsiveStats(statsCards, isMobile),
                          SizedBox(height: isMobile ? 18 : isTablet ? 28 : 40),
                          // Search and Filter Bar
                          _buildSearchAndSortBar(),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  if (filteredProducts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 32 : 48),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: isMobile ? 64 : 96,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: isMobile ? 24 : 32),
                            Text(
                              _searchQuery.isEmpty ? 'No products yet' : 'No products found',
                              style: TextStyle(
                                fontSize: isMobile ? 20 : 28,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Start by adding your first product'
                                  : 'Try adjusting your search criteria',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: isMobile ? 16 : 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: 8),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - (isMobile ? 320 : 400),
                          child: _buildResponsiveProductList(filteredProducts, isMobile),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProductFormScreen(),
                      ),
                    );
                  },
                  child: Icon(Icons.add),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                )
              : null,
        );
      },
    );
  }
}
