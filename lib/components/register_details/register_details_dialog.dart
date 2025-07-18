import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_2/models/register_details_models.dart';
import 'package:pos_2/models/register_entry.dart';

void showRegisterDetailsDialog(
  BuildContext context,
  List<RegisterEntry> registerEntries,
  List<SoldProduct> soldProducts,
  List<BrandSales> brandSales,
  List<ServiceTypeSummary> serviceTypes,
  DateTime startDate,
  DateTime endDate,
  double totalRefund,
  double totalPayment,
  double creditSales,
  double finalSales,
  double computedTotal,
  double discount,
  double shipping,
  String user,
  String email,
  String location,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return RegisterDetailsDialog(
        registerEntries: registerEntries,
        soldProducts: soldProducts,
        brandSales: brandSales,
        serviceTypes: serviceTypes,
        startDate: startDate,
        endDate: endDate,
        totalRefund: totalRefund,
        totalPayment: totalPayment,
        creditSales: creditSales,
        finalSales: finalSales,
        computedTotal: computedTotal,
        discount: discount,
        shipping: shipping,
        user: user,
        email: email,
        location: location,
      );
    },
  );
}

class RegisterDetailsDialog extends StatelessWidget {
  final List<RegisterEntry> registerEntries;
  final List<SoldProduct> soldProducts;
  final List<BrandSales> brandSales;
  final List<ServiceTypeSummary> serviceTypes;
  final DateTime startDate;
  final DateTime endDate;
  final double totalRefund;
  final double totalPayment;
  final double creditSales;
  final double finalSales;
  final double computedTotal;
  final double discount;
  final double shipping;
  final String user;
  final String email;
  final String location;

  const RegisterDetailsDialog({
    super.key,
    required this.registerEntries,
    required this.soldProducts,
    required this.brandSales,
    required this.serviceTypes,
    required this.startDate,
    required this.endDate,
    required this.totalRefund,
    required this.totalPayment,
    required this.creditSales,
    required this.finalSales,
    required this.computedTotal,
    required this.discount,
    required this.shipping,
    required this.user,
    required this.email,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return AlertDialog(
      title: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Register Details (${DateFormat.yMd().add_jm().format(startDate)} - ${DateFormat.yMd().add_jm().format(endDate)})',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 800,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRegisterSummary(currencyFormat),
              const SizedBox(height: 20),
              _buildProductSales(currencyFormat),
              const SizedBox(height: 20),
              _buildBrandSales(currencyFormat),
              const SizedBox(height: 20),
              _buildServiceTypes(currencyFormat),
              const SizedBox(height: 20),
              _buildFooterInfo(),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.print),
          label: const Text('Print Mini'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.print),
          label: const Text('Print Detailed'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildRegisterSummary(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Register Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        DataTable(
          columns: const [
            DataColumn(label: Text('Payment Method')),
            DataColumn(label: Text('Sell'), numeric: true),
            DataColumn(label: Text('Expense'), numeric: true),
          ],
          rows: [
            ...registerEntries.map(
              (entry) => DataRow(
                cells: [
                  DataCell(Text(entry.method)),
                  DataCell(Text(currencyFormat.format(entry.sell))),
                  DataCell(Text(currencyFormat.format(entry.expense))),
                ],
              ),
            ),
            DataRow(
              cells: [
                const DataCell(Text('Total Sales', style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(currencyFormat.format(registerEntries.fold<double>(0.0, (sum, item) => sum + item.sell)), style: const TextStyle(fontWeight: FontWeight.bold))),
                const DataCell(Text('')),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Total Refund', style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(currencyFormat.format(totalRefund))),
                const DataCell(Text('')),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Total Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(currencyFormat.format(totalPayment))),
                const DataCell(Text('')),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Credit Sales', style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(currencyFormat.format(creditSales))),
                const DataCell(Text('')),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Final Sales', style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(currencyFormat.format(finalSales))),
                const DataCell(Text('')),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Total Expense', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataCell(Text('')),
                DataCell(Text(currencyFormat.format(registerEntries.fold<double>(0.0, (sum, item) => sum + item.expense)), style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Computed Total = Opening + Sales - Refund - Expense', style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(currencyFormat.format(computedTotal))),
                const DataCell(Text('')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductSales(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Details of Products Sold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('SKU')),
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Quantity'), numeric: true),
            DataColumn(label: Text('Total Amount'), numeric: true),
          ],
          rows: soldProducts.map((product) {
            return DataRow(
              cells: [
                DataCell(Text(product.index.toString())),
                DataCell(Text(product.sku)),
                DataCell(Text(product.product)),
                DataCell(Text(product.quantity.toString())),
                DataCell(Text(currencyFormat.format(product.total))),
              ],
            );
          }).toList(),
        ),
        const Divider(),
        _buildFooterRow('Discount (-)', currencyFormat.format(discount)),
        _buildFooterRow('Shipping (+)', currencyFormat.format(shipping)),
        _buildFooterRow('Grand Total', currencyFormat.format(soldProducts.fold<double>(0.0, (sum, item) => sum + item.total) - discount + shipping), isBold: true),
      ],
    );
  }

  Widget _buildBrandSales(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Details of Products Sold (By Brand)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Brand')),
            DataColumn(label: Text('Quantity'), numeric: true),
            DataColumn(label: Text('Total Amount'), numeric: true),
          ],
          rows: brandSales.map((brand) {
            return DataRow(
              cells: [
                DataCell(Text(brand.index.toString())),
                DataCell(Text(brand.brand)),
                DataCell(Text(brand.quantity.toString())),
                DataCell(Text(currencyFormat.format(brand.total))),
              ],
            );
          }).toList(),
        ),
        const Divider(),
        _buildFooterRow('Discount (-)', currencyFormat.format(discount)),
        _buildFooterRow('Shipping (+)', currencyFormat.format(shipping)),
        _buildFooterRow('Grand Total', currencyFormat.format(brandSales.fold<double>(0.0, (sum, item) => sum + item.total) - discount + shipping), isBold: true),
      ],
    );
  }

  Widget _buildServiceTypes(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Types of Service Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Type of Service')),
            DataColumn(label: Text('Total Amount'), numeric: true),
          ],
          rows: serviceTypes.map((service) {
            return DataRow(
              cells: [
                DataCell(Text(service.index.toString())),
                DataCell(Text(service.type)),
                DataCell(Text(currencyFormat.format(service.amount))),
              ],
            );
          }).toList(),
        ),
        const Divider(),
        _buildFooterRow('Grand Total', currencyFormat.format(serviceTypes.fold<double>(0.0, (sum, item) => sum + item.amount)), isBold: true),
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        _buildInfoRow('User', user),
        _buildInfoRow('Email', email),
        _buildInfoRow('Business Location', location),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildFooterRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}