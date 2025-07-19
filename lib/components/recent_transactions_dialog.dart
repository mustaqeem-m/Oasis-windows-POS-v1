import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_2/models/sell.dart';

class RecentTransactionsDialog extends StatefulWidget {
  const RecentTransactionsDialog({super.key});

  @override
  State<RecentTransactionsDialog> createState() =>
      _RecentTransactionsDialogState();
}

class _RecentTransactionsDialogState extends State<RecentTransactionsDialog> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _selectedTab = 'final';

  @override
  void initState() {
    super.initState();
    _fetchRecentTransactions();
  }

  Future<void> _fetchRecentTransactions() async {
    setState(() {
      _isLoading = true;
    });
    final sales = await Sell().getSells(limit: 10, status: _selectedTab);
    setState(() {
      _transactions = sales;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _buildTitle(),
      content: _buildContent(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions'),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTab('final', '✓ Final'),
            const SizedBox(width: 8),
            _buildTab('quotation', '>_ Quotation'),
            const SizedBox(width: 8),
            _buildTab('draft', '>_ Draft'),
          ],
        ),
      ],
    );
  }

  Widget _buildTab(String status, String label) {
    final isSelected = _selectedTab == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = status;
        });
        _fetchRecentTransactions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return Center(
          child: Text('No recent $_selectedTab transactions found.'));
    }
    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('S.No.')),
            DataColumn(label: Text('Invoice No. & Customer Name')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            return DataRow(
              cells: [
                DataCell(Text((index + 1).toString())),
                DataCell(Text(
                    '${transaction['invoice_no'] ?? ''} (${transaction['customer_name'] ?? 'Walk-In Customer'})')),
                DataCell(Text(NumberFormat('###,##0.00')
                    .format(transaction['final_total'] ?? 0))),
                DataCell(
                  Row(
                    children: [
                      TextButton(onPressed: () {}, child: const Text('[Edit]')),
                      TextButton(
                          onPressed: () {},
                          child: const Text('[Print]')),
                      TextButton(
                          onPressed: () {},
                          child: const Text('[Delete]')),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}