import 'package:flutter/material.dart';
import 'package:pos_2/models/close_register_model.dart';

class CloseRegisterDialog extends StatelessWidget {
  final CloseRegisterModel data;

  const CloseRegisterDialog({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close Register'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register Period: ${data.registerPeriod}'),
            const SizedBox(height: 16),
            _buildSectionTitle('Payment Details'),
            _buildPaymentDetailsTable(data.paymentDetails),
            const SizedBox(height: 16),
            _buildSectionTitle('Totals'),
            _buildTotals(data.totals),
            const SizedBox(height: 16),
            _buildSectionTitle('Sold Products'),
            _buildSoldProductsTable(data.soldProducts),
            const SizedBox(height: 16),
            _buildSectionTitle('Discounts'),
            _buildDiscounts(data.discounts),
            const SizedBox(height: 16),
            _buildSectionTitle('Sold by Brand'),
            _buildBrandSalesTable(data.soldByBrand),
            const SizedBox(height: 16),
            _buildSectionTitle('Service Types'),
            _buildServiceTypesTable(data.serviceTypes),
            const SizedBox(height: 16),
            _buildSectionTitle('Cash Summary'),
            _buildCashSummary(data.cashSummary),
            const SizedBox(height: 16),
            _buildClosingNote(data.closingNote),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Handle close register logic
            Navigator.of(context).pop();
          },
          child: const Text('Close Register'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
  }

  Widget _buildPaymentDetailsTable(List<PaymentDetail> details) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Method')),
        DataColumn(label: Text('Sell')),
        DataColumn(label: Text('Expense')),
      ],
      rows: details
          .map((detail) => DataRow(cells: [
                DataCell(Text(detail.method)),
                DataCell(Text(detail.sell)),
                DataCell(Text(detail.expense)),
              ]))
          .toList(),
    );
  }

  Widget _buildTotals(Totals totals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Sales: ${totals.totalSales}'),
        Text('Refund: ${totals.refund}'),
        Text('Payment: ${totals.payment}'),
        Text('Credit Sales: ${totals.creditSales}'),
        Text('Final Sales: ${totals.finalSales}'),
        Text('Expenses: ${totals.expenses}'),
        Text('Cash Calculation: ${totals.cashCalculation}'),
      ],
    );
  }

  Widget _buildSoldProductsTable(List<SoldProduct> products) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('SKU')),
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Amount')),
      ],
      rows: products
          .map((product) => DataRow(cells: [
                DataCell(Text(product.sku)),
                DataCell(Text(product.product)),
                DataCell(Text(product.quantity)),
                DataCell(Text(product.amount)),
              ]))
          .toList(),
    );
  }

  Widget _buildDiscounts(Discounts discounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discount: ${discounts.discount}'),
        Text('Shipping: ${discounts.shipping}'),
        Text('Grand Total: ${discounts.grandTotal}'),
      ],
    );
  }

  Widget _buildBrandSalesTable(List<BrandSale> sales) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Brand')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Amount')),
      ],
      rows: sales
          .map((sale) => DataRow(cells: [
                DataCell(Text(sale.brand)),
                DataCell(Text(sale.quantity)),
                DataCell(Text(sale.amount)),
              ]))
          .toList(),
    );
  }

  Widget _buildServiceTypesTable(List<ServiceType> types) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Amount')),
      ],
      rows: types
          .map((type) => DataRow(cells: [
                DataCell(Text(type.type)),
                DataCell(Text(type.amount)),
              ]))
          .toList(),
    );
  }

  Widget _buildCashSummary(CashSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Cash: ${summary.totalCash}'),
        Text('Card Slips: ${summary.cardSlips}'),
        Text('Cheques: ${summary.cheques}'),
        Text(summary.denominationNote),
      ],
    );
  }

  Widget _buildClosingNote(ClosingNote note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User: ${note.user}'),
        Text('Email: ${note.email}'),
        Text('Location: ${note.location}'),
      ],
    );
  }
}
