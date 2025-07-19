import 'package:flutter/material.dart';
import 'package:pos_2/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class DiscountDialog extends StatefulWidget {
  const DiscountDialog({super.key});

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late String _selectedDiscountType;
  late TextEditingController _discountAmountController;

  @override
  void initState() {
    super.initState();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    _selectedDiscountType = cartProvider.selectedDiscountType;
    _discountAmountController = TextEditingController(
        text: cartProvider.discountAmount?.toString() ?? '0');
  }

  @override
  void dispose() {
    _discountAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Discount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedDiscountType,
            dropdownColor: Colors.white,
            items: ['fixed', 'percentage']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDiscountType = value;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Discount Type*',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _discountAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Discount Amount*',
              border: const OutlineInputBorder(),
              prefixText:
                  _selectedDiscountType == 'fixed' ? '₹' : '%',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_discountAmountController.text);
            if (amount != null) {
              cartProvider.setDiscountType(_selectedDiscountType);
              cartProvider.updateDiscount(amount.toString());
              cartProvider.calculateSubtotal(
                  cartProvider.selectedTaxId,
                  _selectedDiscountType,
                  amount);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
