import 'package:flutter/material.dart';
import 'package:monthly_bills_app/main.dart';
import 'package:intl/intl.dart';

class BillHistoryScreen extends StatelessWidget {
  final Bill bill;

  BillHistoryScreen({required this.bill});

  String formatMonth(String? month) {
    if (month == null) return 'Unknown';
    final date = DateTime.parse(month + '-01');
    return DateFormat('MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill History: ${bill.name}'),
      ),
      body: bill.previousCycles.isEmpty
          ? Center(child: Text('No history available'))
          : ListView.builder(
              itemCount: bill.previousCycles.length,
              itemBuilder: (context, index) {
                final cycle = bill.previousCycles[index];
                final total = cycle['total'];
                final month = formatMonth(cycle['month']);
                final dates =
                    cycle['dates'] as Map<String, Map<String, dynamic>>?;

                return ExpansionTile(
                  title: Text('$month - Total: Rs. $total'),
                  children: dates?.keys.map<Widget>((date) {
                        final count = dates?[date]?['count'];
                        final value = dates?[date]?['value'];
                        return ListTile(
                          title: Text(date ?? 'Unknown Date'),
                          trailing: Text(
                              'Bills: ${count ?? 0}, Value: Rs. ${value ?? 0}'),
                        );
                      }).toList() ??
                      [],
                );
              },
            ),
    );
  }
}
