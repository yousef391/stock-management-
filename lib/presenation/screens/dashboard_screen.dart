import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../../data/models/product.dart';
import '../../data/models/stock_performa.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/dashboard_period_filter.dart';
import '../widgets/dashboard_stats_card.dart';

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


  List<StockPerforma> _getFilteredPerformas(List<StockPerforma> performas) {
    final startDate = _getStartDate();
    return performas.where((performa) => performa.createdAt.isAfter(startDate)).toList();
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
                                DashboardStatsCard(
                                  title: 'Total Operations',
                                  value: '$totalOperations',
                                  icon: Icons.assignment,
                                  color: Colors.blue,
                                ),
                                DashboardStatsCard(
                                  title: 'Stock In',
                                  value: '$stockInOperations',
                                  icon: Icons.arrow_downward,
                                  color: Colors.green,
                                ),
                                DashboardStatsCard(
                                  title: 'Stock Out',
                                  value: '$stockOutOperations',
                                  icon: Icons.arrow_upward,
                                  color: Colors.red,
                                ),
                                DashboardStatsCard(
                                  title: 'Total Revenue',
                                  value: '${totalValue.toStringAsFixed(2)} DZD',
                                  icon: Icons.attach_money,
                                  color: Colors.orange,
                                ),
                                DashboardStatsCard(
                                  title: 'Total Profit',
                                  value: '${totalProfit.toStringAsFixed(2)} DZD',
                                  icon: Icons.trending_up,
                                  color: Colors.purple,
                                ),
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
