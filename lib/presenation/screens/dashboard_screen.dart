import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../../data/models/product.dart';
import '../../data/models/stock_performa.dart';
import '../viewmodels/auth_viewmodel.dart';

enum PeriodFilter {
  lastDay,
  last7Days,
  lastMonth,
  allTime,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PeriodFilter _selectedPeriod = PeriodFilter.allTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productVM = context.read<ProductViewModel>();
      final stockVM = context.read<StockViewModel>();
      final userId = context.read<AuthViewModel>().user?.id;
      if (userId != null) {
        productVM.fetchProducts(userId);
        stockVM.fetchPerformas(userId);
      }
    });
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case PeriodFilter.lastDay:
        return DateTime(now.year, now.month, now.day);
      case PeriodFilter.last7Days:
        return now.subtract(Duration(days: 7));
      case PeriodFilter.lastMonth:
        return DateTime(now.year, now.month - 1, now.day);
      case PeriodFilter.allTime:
        return DateTime(1900); // Very old date to include everything
    }
  }

  String _getPeriodDisplayName() {
    switch (_selectedPeriod) {
      case PeriodFilter.lastDay:
        return 'Last 24 Hours';
      case PeriodFilter.last7Days:
        return 'Last 7 Days';
      case PeriodFilter.lastMonth:
        return 'Last Month';
      case PeriodFilter.allTime:
        return 'All Time';
    }
  }

  List<StockPerforma> _getFilteredPerformas(List<StockPerforma> performas) {
    final startDate = _getStartDate();
    return performas.where((performa) => performa.createdAt.isAfter(startDate)).toList();
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    // For products, we'll show current state regardless of period
    // But we can filter based on when they were last updated if needed
    return products;
  }

  Widget _buildPeriodFilterChips() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text('24H'),
                selected: _selectedPeriod == PeriodFilter.lastDay,
                onSelected: (selected) {
                  setState(() {
                    _selectedPeriod = PeriodFilter.lastDay;
                  });
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              ),
              FilterChip(
                label: Text('7 Days'),
                selected: _selectedPeriod == PeriodFilter.last7Days,
                onSelected: (selected) {
                  setState(() {
                    _selectedPeriod = PeriodFilter.last7Days;
                  });
                },
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
              ),
              FilterChip(
                label: Text('Month'),
                selected: _selectedPeriod == PeriodFilter.lastMonth,
                onSelected: (selected) {
                  setState(() {
                    _selectedPeriod = PeriodFilter.lastMonth;
                  });
                },
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
              ),
              FilterChip(
                label: Text('All Time'),
                selected: _selectedPeriod == PeriodFilter.allTime,
                onSelected: (selected) {
                  setState(() {
                    _selectedPeriod = PeriodFilter.allTime;
                  });
                },
                selectedColor: Colors.purple.withOpacity(0.2),
                checkmarkColor: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
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
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(String title, List<Widget> children) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert(Product product) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Low stock: ${product.stock} units',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductCard(Product product, int rank) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Stock: ${product.stock} | Profit: ${product.formattedProfit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildResponsiveList(List<Widget> items, bool isMobile) {
    if (isMobile) {
      return Column(children: items);
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        childAspectRatio: 3,
        physics: NeverScrollableScrollPhysics(),
        children: items,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isDesktop = constraints.maxWidth >= 1200;
        return Scaffold(
          body: Consumer<AuthViewModel>(
            builder: (context, auth, child) {
              if (auth.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (auth.user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Please log in to access the dashboard'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text('Go to Login'),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 24 : 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                child: Icon(Icons.dashboard, size: isMobile ? 22 : isTablet ? 28 : 36, color: Colors.blue),
                              ),
                              SizedBox(width: isMobile ? 10 : isTablet ? 14 : 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard',
                                      style: TextStyle(
                                        fontSize: isMobile ? 22 : isTablet ? 28 : 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      'Welcome back, ${auth.user!.email}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : isTablet ? 15 : 18,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 18 : isTablet ? 28 : 40),
                          // Period Filter
                          Text(
                            'Statistics Period',
                            style: TextStyle(
                              fontSize: isMobile ? 15 : isTablet ? 17 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: isMobile ? 10 : isTablet ? 14 : 18),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildPeriodChip('Last Day', 'day', isMobile),
                                SizedBox(width: 8),
                                _buildPeriodChip('Last 7 Days', 'week', isMobile),
                                SizedBox(width: 8),
                                _buildPeriodChip('Last Month', 'month', isMobile),
                                SizedBox(width: 8),
                                _buildPeriodChip('All Time', 'all', isMobile),
                              ],
                            ),
                          ),
                          SizedBox(height: isMobile ? 18 : isTablet ? 28 : 40),
                          // Statistics Cards
                          Consumer<StockViewModel>(
                            builder: (context, stockVM, child) {
                              if (stockVM.isLoading) {
                                return Center(child: CircularProgressIndicator());
                              }
                              final filteredPerformas = _getFilteredPerformas(stockVM.performas);
                              final totalOperations = filteredPerformas.length;
                              final stockInOperations = filteredPerformas.where((p) => p.type == 'in').length;
                              final stockOutOperations = filteredPerformas.where((p) => p.type == 'out').length;
                              final totalValue = filteredPerformas
                                  .where((p) => p.type == 'out')
                                  .fold<double>(0, (sum, p) {
                                return sum + p.items.fold<double>(0, (itemSum, item) =>
                                  itemSum + (item.quantity * item.sellPrice)
                                );
                              });
                              final totalProfit = filteredPerformas
                                  .where((p) => p.type == 'out')
                                  .fold<double>(0, (sum, p) {
                                return sum + p.items.fold<double>(0, (itemSum, item) =>
                                  itemSum + (item.quantity * (item.sellPrice - item.buyPrice))
                                );
                              });
                              final statsCards = [
                                _buildStatsCard('Total Operations', '$totalOperations', Icons.assignment, Colors.blue),
                                _buildStatsCard('Stock In', '$stockInOperations', Icons.arrow_downward, Colors.green),
                                _buildStatsCard('Stock Out', '$stockOutOperations', Icons.arrow_upward, Colors.red),
                                _buildStatsCard('Total Revenue', '${totalValue.toStringAsFixed(2)} DZD', Icons.attach_money, Colors.orange),
                                _buildStatsCard('Total Profit', '${totalProfit.toStringAsFixed(2)} DZD', Icons.trending_up, Colors.purple),
                              ];
                              return _buildResponsiveStats(statsCards, isMobile);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPeriodChip(String label, String value, bool isMobile) {
    PeriodFilter periodFilter;
    switch (value) {
      case 'day':
        periodFilter = PeriodFilter.lastDay;
        break;
      case 'week':
        periodFilter = PeriodFilter.last7Days;
        break;
      case 'month':
        periodFilter = PeriodFilter.lastMonth;
        break;
      case 'all':
        periodFilter = PeriodFilter.allTime;
        break;
      default:
        periodFilter = PeriodFilter.allTime;
    }
    
    final isSelected = _selectedPeriod == periodFilter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = periodFilter;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
      ),
    );
  }
}
