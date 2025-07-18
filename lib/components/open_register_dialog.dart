
import 'package:flutter/material.dart';

class OpenRegisterDialog extends StatefulWidget {
  final Function(double) onConfirm;

  const OpenRegisterDialog({Key? key, required this.onConfirm}) : super(key: key);

  @override
  _OpenRegisterDialogState createState() => _OpenRegisterDialogState();
}

class _OpenRegisterDialogState extends State<OpenRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _openingBalanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Register'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _openingBalanceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Opening Balance',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an opening balance';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(double.parse(_openingBalanceController.text));
              Navigator.of(context).pop();
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
