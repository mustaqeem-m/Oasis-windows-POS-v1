import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_2/models/sell.dart';
import 'package:pos_2/models/sellDatabase.dart';

class SuspendedSalesModal extends StatelessWidget {
  final List<Map<String, dynamic>> suspendedSales;

  const SuspendedSalesModal({super.key, required this.suspendedSales});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todaysSales = suspendedSales.where((sale) {
      final transactionDate = DateTime.parse(sale['transaction_date']);
      return transactionDate.year == today.year &&
          transactionDate.month == today.month &&
          transactionDate.day == today.day;
    }).toList();

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: const Text(
        'Suspended Sales',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: todaysSales.isEmpty
            ? const Center(
                child: Text(
                  'No suspended bills today.',
                  style: TextStyle(color: Colors.white, fontSize: 18.0),
                ),
              )
            : GridView.builder(
                itemCount: todaysSales.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final sale = todaysSales[index];
                  return SuspendedSaleCard(sale: sale);
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }
}

class SuspendedSaleCard extends StatelessWidget {
  final Map<String, dynamic> sale;

  const SuspendedSaleCard({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final transactionDate = DateTime.parse(sale['transaction_date']);
    final formattedDate = DateFormat('MM/dd/yyyy').format(transactionDate);
    final totalAmount = NumberFormat.currency(locale: 'en_IN', symbol: '₹')
        .format(sale['invoice_amount']);

    return FutureBuilder<String>(
      future: SellDatabase().countSellLines(sellId: sale['id']),
      builder: (context, snapshot) {
        final totalItems = snapshot.data ?? '0';
        return Card(
          color: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale['suspend_note'] ?? 'Suspended',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Invoice: ${sale['invoice_no']}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Date: $formattedDate',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Customer: ${sale['customer_name'] ?? 'Walk-In Customer'}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Total Items: $totalItems',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Total: $totalAmount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Handle Edit Sale
                      },
                      child: const Text(
                        'Edit Sale →',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle Delete
                      },
                      child: const Text(
                        'Delete 🗑',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
