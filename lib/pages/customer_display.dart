import 'package:flutter/material.dart';
import 'package:pos_2/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';

class CustomerDisplayScreen extends StatelessWidget {
  const CustomerDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int themeType = 1;
    ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Display'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: EdgeInsets.all(MySize.size16!),
            child: Column(
              children: [
                _buildHeader(themeData),
                Expanded(
                  child: _buildProductList(provider, themeData),
                ),
                _buildSummary(provider, themeData),
                _buildFooter(provider, themeData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData themeData) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: themeData.dividerColor,
                width: 2.0,
              ),
            ),
          ),
          children: [
            _headerCell('Product', themeData),
            _headerCell('Quantity', themeData),
            _headerCell('Price inc. tax', themeData),
            _headerCell('Subtotal', themeData),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(String text, ThemeData themeData) {
    return Padding(
      padding: EdgeInsets.all(MySize.size8!),
      child: Text(
        text,
        style: AppTheme.getTextStyle(
          themeData.textTheme.titleMedium,
          fontWeight: 700,
          color: themeData.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildProductList(CartProvider provider, ThemeData themeData) {
    return ListView.builder(
      itemCount: provider.cartItems.length,
      itemBuilder: (context, index) {
        final item = provider.cartItems[index];
        final subtotal = (double.parse(provider.calculateInlineUnitPrice(
                item['unit_price'],
                item['tax_rate_id'],
                item['discount_type'],
                item['discount_amount'])) *
            item['quantity']);
        return Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              children: [
                _productCell(item['name'], themeData),
                _productCell(item['quantity'].toString(), themeData),
                _productCell(
                    '₹${Helper().formatCurrency(item['unit_price'])}',
                    themeData),
                _productCell(
                    '₹${Helper().formatCurrency(subtotal)}',
                    themeData),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _productCell(String text, ThemeData themeData) {
    return Padding(
      padding: EdgeInsets.all(MySize.size8!),
      child: Text(
        text,
        style: AppTheme.getTextStyle(
          themeData.textTheme.bodyLarge,
          color: themeData.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSummary(CartProvider provider, ThemeData themeData) {
    final subTotal = provider.calculateSubTotal();
    final total = provider.calculateSubtotal(provider.selectedTaxId,
        provider.selectedDiscountType, provider.discountAmount);
    num taxAmount = 0;
    for (var value in provider.taxListMap) {
      if (value['id'] == provider.selectedTaxId) {
        taxAmount = value['amount'] as num;
      }
    }
    final tax = (subTotal * taxAmount) / 100;

    return Padding(
      padding: EdgeInsets.all(MySize.size16!),
      child: Column(
        children: [
          _summaryRow('Items:', provider.cartItems.length.toString(), themeData),
          _summaryRow(
              'Total:', '₹${Helper().formatCurrency(subTotal)}', themeData),
          _summaryRow('Discount (-):',
              '₹${Helper().formatCurrency(provider.discountAmount ?? 0.0)}', themeData),
          _summaryRow(
              'Order Tax (+):', '₹${Helper().formatCurrency(tax)}', themeData),
          _summaryRow('Shipping (+):', '₹0.00', themeData),
          Divider(),
          _summaryRow(
              'Total Payable:', '₹${Helper().formatCurrency(total)}', themeData,
              valueColor: Colors.green, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, ThemeData themeData,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MySize.size4!),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.getTextStyle(
              themeData.textTheme.bodyLarge,
              color: themeData.colorScheme.onSurface,
              fontWeight: isBold ? 700 : 400,
            ),
          ),
          Text(
            value,
            style: AppTheme.getTextStyle(
              themeData.textTheme.bodyLarge,
              color: valueColor ?? themeData.colorScheme.onSurface,
              fontWeight: isBold ? 700 : 400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(CartProvider provider, ThemeData themeData) {
    return Container(
      color: Colors.orange,
      padding: EdgeInsets.all(MySize.size16!),
      child: Column(
        children: [
          _footerRow('Total Paying:', '₹0.00', themeData),
          _footerRow('Change Return:', '₹0.00', themeData),
          _footerRow('Balance:', '₹0.00', themeData,
              valueColor: Colors.red),
        ],
      ),
    );
  }

  Widget _footerRow(String title, String value, ThemeData themeData,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MySize.size4!),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.getTextStyle(
              themeData.textTheme.titleMedium,
              color: Colors.white,
              fontWeight: 700,
            ),
          ),
          Text(
            value,
            style: AppTheme.getTextStyle(
              themeData.textTheme.titleMedium,
              color: valueColor ?? Colors.white,
              fontWeight: 700,
            ),
          ),
        ],
      ),
    );
  }
}
