import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/stock_performa.dart';
import '../viewmodels/company_viewmodel.dart';

class PerformaCard extends StatelessWidget {
  final StockPerforma performa;
  final bool isMobile;
  final void Function(StockPerforma) onTap;
  final void Function(StockPerforma) onGeneratePdf;
  final void Function(StockPerforma) onDownloadPdf;
  final String Function(String?, bool) displayPerformaNumberShort;

  const PerformaCard({
    Key? key,
    required this.performa,
    required this.isMobile,
    required this.onTap,
    required this.onGeneratePdf,
    required this.onDownloadPdf,
    required this.displayPerformaNumberShort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final operationType = performa.type;
    final isStockIn = operationType == 'in';
    final totalQuantity = performa.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalValue = performa.items.fold<double>(0, (sum, item) => sum + (item.quantity * (isStockIn ? item.buyPrice : item.sellPrice)));
    return FadeTransition(
      opacity: AlwaysStoppedAnimation(1.0),
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
            onTap: () => onTap(performa),
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
                        _buildInfoChip('Qty', '$totalQuantity', Colors.orange, Icons.shopping_cart, fontSize: 10),
                        _buildInfoChip('Value', '${totalValue.toStringAsFixed(0)}', Colors.green, Icons.attach_money, fontSize: 10),
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
                          child: _buildInfoChip('Quantity', '$totalQuantity', Colors.orange, Icons.shopping_cart),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoChip('Value', '${totalValue.toStringAsFixed(2)} DZD', Colors.green, Icons.attach_money),
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
                          IconButton(
                            icon: Icon(Icons.download, color: Colors.green, size: isMobile ? 14 : 20),
                            onPressed: () => onDownloadPdf(performa),
                          ),
                        if (performa.pdfUrl == null)
                          IconButton(
                            icon: Icon(Icons.picture_as_pdf, color: Colors.blue, size: isMobile ? 14 : 20),
                            tooltip: 'Generate PDF',
                            onPressed: () => onGeneratePdf(performa),
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
} 