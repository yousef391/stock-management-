import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../../data/models/product.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/stock_performa.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/company_viewmodel.dart';
import '../widgets/stock_operation_dialog.dart';

class StockItem {
  final Product product;
  int quantity;

  StockItem({required this.product, required this.quantity});
}

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'in', 'out'
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockVM = context.read<StockViewModel>();
      final userId = context.read<AuthViewModel>().user?.id;
      if (userId != null) {
        stockVM.fetchProducts(userId);
        stockVM.fetchPerformas(userId);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showStockOperationDialog() {
    print('Opening StockOperationDialog');
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            try {
              return StockOperationDialog(
                onOperationComplete: () {
                  // Refresh the performas after operation
                  final userId = context.read<AuthViewModel>().user?.id;
                  if (userId != null) {
                    context.read<StockViewModel>().fetchPerformas(userId);
                  }
                },
              );
            } catch (e, stack) {
              print('Error building StockOperationDialog: $e\n$stack');
              return AlertDialog(
                title: Text('Build Error'),
                content: Text('Failed to build StockOperationDialog: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              );
            }
          },
        );
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to open operation dialog: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _downloadPerforma(StockPerforma performa) async {
    // TODO: When testing on a real device/emulator, check the printed URL below.
    if (performa.pdfUrl != null) {
      try {
        print('Trying to open PDF: ${performa.pdfUrl}');
        final url = Uri.parse(performa.pdfUrl!);
        if (url.scheme == 'http') {
          print('WARNING: HTTP URLs may not work on all devices. Use HTTPS if possible.');
        }
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          print('ERROR: canLaunchUrl returned false for: ${performa.pdfUrl}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open PDF. URL: ${performa.pdfUrl}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        print('Exception while opening PDF: ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  String displayPerformaNumberShort(String? number, bool isMobile) {
    if (!isMobile || number == null || number.length <= 12) return number ?? '-';
    return number.substring(0, 8) + '...';
  }

  String truncateMobile(String text, {int max = 18}) {
    if (text.length <= max) return text;
    return text.substring(0, max) + '...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StockViewModel>(
        builder: (context, stockVM, child) {
          if (stockVM.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading stock operations...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (stockVM.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${stockVM.error}',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userId = context.read<AuthViewModel>().user?.id;
                      if (userId != null) {
                        stockVM.fetchProducts(userId);
                        stockVM.fetchPerformas(userId);
                      }
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredPerformas = _getFilteredPerformas(stockVM.performas);
          final totalOperations = filteredPerformas.length;
          final stockInOperations = filteredPerformas.where((p) => p.type == 'in').length;
          final stockOutOperations = filteredPerformas.where((p) => p.type == 'out').length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
              final isDesktop = constraints.maxWidth >= 1200;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 24 : 40),
                      child: Column(
                        children: [
                          // Enhanced Header
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
                                      'Stock Operations',
                                      style: TextStyle(
                                        fontSize: isMobile ? 22 : isTablet ? 28 : 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Text(
                                      'Manage and track your inventory operations',
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : isTablet ? 15 : 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMobile)
                                ElevatedButton.icon(
                                  onPressed: _showStockOperationDialog,
                                  icon: Icon(Icons.add),
                                  label: Text('New Operation'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 18 : isTablet ? 28 : 40),
                          // Enhanced Statistics Cards
                          Consumer<StockViewModel>(
                            builder: (context, stockVM, child) {
                              final filteredPerformas = _getFilteredPerformas(stockVM.performas);
                              final totalOperations = filteredPerformas.length;
                              final stockInOperations = filteredPerformas.where((p) => p.type == 'in').length;
                              final stockOutOperations = filteredPerformas.where((p) => p.type == 'out').length;
                              final statsCards = [
                                _buildStatsCard('Total Operations', '$totalOperations', Icons.assignment, Colors.blue),
                                _buildStatsCard('Stock In', '$stockInOperations', Icons.arrow_downward, Colors.green),
                                _buildStatsCard('Stock Out', '$stockOutOperations', Icons.arrow_upward, Colors.red),
                              ];
                              return _buildResponsiveStats(statsCards, isMobile);
                            },
                          ),
                          SizedBox(height: isMobile ? 18 : isTablet ? 28 : 40),
                          // Enhanced Search and Filter Bar
                          _buildSearchAndFilterBar(),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  if (filteredPerformas.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                size: isMobile ? 64 : 96,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              _searchQuery.isEmpty ? 'No stock operations yet' : 'No performas found',
                              style: TextStyle(
                                fontSize: isMobile ? 20 : 28,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Start by creating your first stock operation'
                                  : 'Try adjusting your search criteria',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: isMobile ? 16 : 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            if (_searchQuery.isEmpty)
                              ElevatedButton.icon(
                                onPressed: _showStockOperationDialog,
                                icon: Icon(Icons.add),
                                label: Text('Create First Operation'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildPerformaCard(filteredPerformas[index], isMobile),
                          childCount: filteredPerformas.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) return SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _showStockOperationDialog,
            icon: Icon(Icons.add),
            label: Text('New Operation'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  // Test method for debugging stock out issues
  void _testSimpleStockOut() {
    final stockVM = context.read<StockViewModel>();
    final products = stockVM.products;
    
    if (products.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No products available for testing')),
        );
      });
      return;
    }
    
    // Use the first product for testing
    final testProduct = products.first;
    final testQuantity = 1;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Test Stock Out'),
          content: Text('Test removing $testQuantity unit from ${testProduct.name}?\nCurrent stock: ${testProduct.stock}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final userId = context.read<AuthViewModel>().user?.id;
                if (userId != null) {
                  await stockVM.testSimpleStockOut(
                    product: testProduct,
                    quantity: testQuantity,
                    userId: userId,
                  );
                }
                
                if (stockVM.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test failed: ${stockVM.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test successful! Stock updated.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('Test'),
            ),
          ],
        ),
      );
    });
  }

  List<StockPerforma> _getFilteredPerformas(List<StockPerforma> performas) {
    var filtered = performas.where((performa) {
      final matchesSearch = performa.performaNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterType == 'all' || 
                           (_filterType == 'in' && performa.type == 'in') ||
                           (_filterType == 'out' && performa.type == 'out');
      return matchesSearch && matchesFilter;
    }).toList();

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

  Widget _buildSearchAndFilterBar() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isMobile ? 4 : 10,
            offset: Offset(0, isMobile ? 2 : 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search performas...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: isMobile ? 12 : 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: isMobile ? 18 : 24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20, vertical: isMobile ? 8 : 16),
            ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', Colors.blue, isMobile: isMobile),
                SizedBox(width: isMobile ? 4 : 8),
                _buildFilterChip('Stock In', 'in', Colors.green, isMobile: isMobile),
                SizedBox(width: isMobile ? 4 : 8),
                _buildFilterChip('Stock Out', 'out', Colors.red, isMobile: isMobile),
                SizedBox(width: isMobile ? 8 : 16),
                // Test button for debugging
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: () => _testSimpleStockOut(),
                    icon: Icon(Icons.bug_report, size: 16),
                    label: Text('Test Stock Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color, {bool isMobile = false}) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: isMobile ? 11 : 14,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 14 : 20)),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 8),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: isMobile ? 6 : 15,
              offset: Offset(0, isMobile ? 4 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 16),
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 18 : 28),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 2 : 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: isMobile ? 12 : 16),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 20),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 20 : 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 12 : 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformaCard(StockPerforma performa, bool isMobile) {
    final operationType = performa.type;
    final isStockIn = operationType == 'in';
    
    // Calculate totals from items
    final totalQuantity = performa.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalValue = performa.items.fold<double>(0, (sum, item) => 
      sum + (item.quantity * (isStockIn ? item.buyPrice : item.sellPrice))
    );
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 12, vertical: isMobile ? 4 : 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: isMobile ? 8 : 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showPerformaDetails(performa),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 10 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with operation type
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isStockIn 
                                ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)]
                                : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 16),
                        ),
                        child: Icon(
                          isStockIn ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isStockIn ? Colors.green : Colors.red,
                          size: isMobile ? 18 : 28,
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Performa: ${displayPerformaNumberShort(performa.performaNumber, isMobile)}',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: isMobile ? 2 : 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: isMobile ? 10 : 14, color: Colors.grey[500]),
                                SizedBox(width: 4),
                                Text(
                                  _formatDate(performa.createdAt),
                                  style: TextStyle(
                                    fontSize: isMobile ? 10 : 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 4 : 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isStockIn 
                                ? [Colors.green, Colors.green.shade700]
                                : [Colors.red, Colors.red.shade700],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
                          boxShadow: [
                            BoxShadow(
                              color: (isStockIn ? Colors.green : Colors.red).withOpacity(0.3),
                              blurRadius: isMobile ? 4 : 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          isStockIn ? '📥 IN' : '📤 OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 8 : 20),
                  // Statistics Row
                  if (isMobile)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoChip('Products', '${performa.items.length}', Colors.blue, Icons.inventory, fontSize: 10),
                        _buildInfoChip('Qty', '${performa.items.fold<int>(0, (sum, item) => sum + item.quantity)}', Colors.orange, Icons.shopping_cart, fontSize: 10),
                        _buildInfoChip('Value', '${performa.items.fold<double>(0, (sum, item) => sum + (item.quantity * (isStockIn ? item.buyPrice : item.sellPrice))).toStringAsFixed(0)}', Colors.green, Icons.attach_money, fontSize: 10),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip('Products', '${performa.items.length}', Colors.blue, Icons.inventory),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoChip('Quantity', '${performa.items.fold<int>(0, (sum, item) => sum + item.quantity)}', Colors.orange, Icons.shopping_cart),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoChip('Value', '${performa.items.fold<double>(0, (sum, item) => sum + (item.quantity * (isStockIn ? item.buyPrice : item.sellPrice))).toStringAsFixed(2)} DZD', Colors.green, Icons.attach_money),
                        ),
                      ],
                    ),
                  SizedBox(height: isMobile ? 8 : 16),
                  // PDF Status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 6 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: performa.pdfUrl != null 
                            ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                            : [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                      border: Border.all(
                        color: performa.pdfUrl != null 
                            ? Colors.green.withOpacity(0.3) 
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 4 : 8),
                          decoration: BoxDecoration(
                            color: performa.pdfUrl != null ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(isMobile ? 4 : 8),
                          ),
                          child: Icon(
                            performa.pdfUrl != null ? Icons.picture_as_pdf : Icons.error,
                            color: Colors.white,
                            size: isMobile ? 12 : 16,
                          ),
                        ),
                        SizedBox(width: isMobile ? 6 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                performa.pdfUrl != null 
                                    ? 'PDF Available'
                                    : 'PDF Generation Failed',
                                style: TextStyle(
                                  color: performa.pdfUrl != null ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 10 : 14,
                                ),
                              ),
                              Text(
                                performa.pdfUrl != null 
                                    ? 'Tap to download'
                                    : 'You can try to generate PDF again',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isMobile ? 9 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (performa.pdfUrl != null)
                          Icon(
                            Icons.download,
                            color: Colors.green,
                            size: isMobile ? 14 : 20,
                          ),
                        if (performa.pdfUrl == null)
                          IconButton(
                            icon: Icon(Icons.picture_as_pdf, color: Colors.blue, size: isMobile ? 14 : 20),
                            tooltip: 'Generate PDF',
                            onPressed: () => _generatePdfForPerforma(performa),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showPerformaDetails(StockPerforma performa) {
    final isStockIn = performa.type == 'in';
    final totalQuantity = performa.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalValue = performa.items.fold<double>(0, (sum, item) => 
      sum + (item.quantity * (isStockIn ? item.buyPrice : item.sellPrice))
    );
    final companyInfo = context.read<CompanyViewModel>().companyInfo;
    final isMobile = MediaQuery.of(context).size.width < 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) {
          String displayPerformaId(String? id) {
            if (!isMobile || id == null || id.length <= 12) return id ?? '-';
            return id.substring(0, 8) + '...';
          }
          String displayPerformaNumber(String? number) {
            if (!isMobile || number == null || number.length <= 12) return number ?? '-';
            return number.substring(0, 8) + '...';
          }
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 14 : 16)),
            child: Container(
              width: isMobile ? MediaQuery.of(context).size.width * 0.98 : 600,
              padding: EdgeInsets.all(isMobile ? 10 : 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Info
                    if (companyInfo != null) ...[
                      Text(companyInfo.name, style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(truncateMobile(companyInfo.address), style: TextStyle(fontSize: isMobile ? 11 : 14)),
                      Text('Phone: ${companyInfo.phone}', style: TextStyle(fontSize: isMobile ? 11 : 14)),
                      if (companyInfo.email != null && companyInfo.email!.isNotEmpty)
                        Text('Email: ${truncateMobile(companyInfo.email!)}', style: TextStyle(fontSize: isMobile ? 11 : 14)),
                      Divider(height: isMobile ? 12 : 24),
                    ],
                    // Performa Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Performa ID: ${displayPerformaId(performa.id)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 14)),
                        SizedBox(height: isMobile ? 2 : 4),
                        Text('Performa Number: ${displayPerformaNumber(performa.performaNumber)}', style: TextStyle(fontSize: isMobile ? 11 : 14)),
                        SizedBox(height: isMobile ? 2 : 4),
                        Text('Operation Type: ${performa.type.toUpperCase()}', style: TextStyle(fontSize: isMobile ? 11 : 14)),
                        SizedBox(height: isMobile ? 2 : 4),
                        Text('Date: ${_formatDate(performa.createdAt)}', style: TextStyle(fontSize: isMobile ? 11 : 14, color: Colors.grey[600])),
                      ],
                    ),
                    Divider(height: isMobile ? 12 : 24),
                    // Recipient Info
                    if (performa.recipientName != null || performa.recipientCompany != null || performa.recipientAddress != null || performa.recipientPhone != null) ...[
                      Text(isStockIn ? 'Invoice From (Supplier Info)' : 'Invoice To (Client Info)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 8 : 14 ,overflow: TextOverflow.clip)),
                      if (performa.recipientName != null) Text(truncateMobile(performa.recipientName!), style: TextStyle(fontSize: isMobile ? 11 : 14)),
                      if (performa.recipientCompany != null) Text(truncateMobile(performa.recipientCompany!), style: TextStyle(fontSize: isMobile ? 11 : 14)),
                      if (performa.recipientAddress != null) Text(truncateMobile(performa.recipientAddress!), style: TextStyle(fontSize: isMobile ? 11 : 14)),
                      if (performa.recipientPhone != null) Text('Phone: ${performa.recipientPhone!}', style: TextStyle(fontSize: isMobile ? 11 : 14)),
                      Divider(height: isMobile ? 12 : 24),
                    ],
                    // Summary
                    Row(
                      children: [
                        Expanded(child: _buildSimpleDetail('Products', '${performa.items.length}', isMobile)),
                        Expanded(child: _buildSimpleDetail('Quantity', '$totalQuantity', isMobile)),
                        Expanded(child: _buildSimpleDetail(isStockIn ? 'Total Cost' : 'Total Revenue', '${totalValue.toStringAsFixed(2)} DZD', isMobile)),
                      ],
                    ),
                    SizedBox(height: isMobile ? 10 : 20),
                    // Products List
                    Text('Products', style: TextStyle(fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: isMobile ? 6 : 12),
                    Container(
                      height: isMobile ? 120 : 320,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: performa.items.length,
                        itemBuilder: (context, index) {
                          final item = performa.items[index];
                          final price = isStockIn ? item.buyPrice : item.sellPrice;
                          final total = item.quantity * price;
                          return Container(
                            padding: EdgeInsets.all(isMobile ? 6 : 12),
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    truncateMobile(item.productName),
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: isMobile ? 11 : 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Expanded(
                                  child: Text('${item.quantity}', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 11 : 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Expanded(
                                  child: Text('${total.toStringAsFixed(2)} DZD', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 11 : 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: isMobile ? 10 : 20),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Close', style: TextStyle(fontSize: isMobile ? 12 : 16)),
                          ),
                        ),
                        if (performa.pdfUrl != null) ...[
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _downloadPerforma(performa);
                              },
                              icon: Icon(Icons.download, size: isMobile ? 12 : 16),
                              label: Text('Download PDF', style: TextStyle(fontSize: isMobile ? 12 : 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildSimpleDetail(String label, String value, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 13 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 9 : 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color, IconData icon, {double fontSize = 16}) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: fontSize),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize - 5,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdfForPerforma(StockPerforma performa) async {
    final stockVM = context.read<StockViewModel>();
    final userId = context.read<AuthViewModel>().user?.id;
    final companyInfo = context.read<CompanyViewModel>().companyInfo;
    if (userId == null || companyInfo == null) return;
    try {
      await stockVM.generateAndUploadPerformaPdf(
        performa: performa,
        items: performa.items,
        performaNumber: performa.performaNumber,
        operationType: performa.type,
        companyInfo: companyInfo,
      );
      await stockVM.fetchPerformas(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }
}