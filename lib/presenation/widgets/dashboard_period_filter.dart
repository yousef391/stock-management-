import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';

class DashboardPeriodFilter extends StatelessWidget {
  final PeriodFilter selectedPeriod;
  final ValueChanged<PeriodFilter> onChanged;
  const DashboardPeriodFilter({
    Key? key,
    required this.selectedPeriod,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                selected: selectedPeriod == PeriodFilter.lastDay,
                onSelected: (selected) => onChanged(PeriodFilter.lastDay),
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              ),
              FilterChip(
                label: Text('7 Days'),
                selected: selectedPeriod == PeriodFilter.last7Days,
                onSelected: (selected) => onChanged(PeriodFilter.last7Days),
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
              ),
              FilterChip(
                label: Text('Month'),
                selected: selectedPeriod == PeriodFilter.lastMonth,
                onSelected: (selected) => onChanged(PeriodFilter.lastMonth),
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
              ),
              FilterChip(
                label: Text('All Time'),
                selected: selectedPeriod == PeriodFilter.allTime,
                onSelected: (selected) => onChanged(PeriodFilter.allTime),
                selectedColor: Colors.purple.withOpacity(0.2),
                checkmarkColor: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
} 