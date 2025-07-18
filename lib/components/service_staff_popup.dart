
import 'package:flutter/material.dart';

class ServiceStaffPopup extends StatefulWidget {
  const ServiceStaffPopup({Key? key}) : super(key: key);

  @override
  _ServiceStaffPopupState createState() => _ServiceStaffPopupState();
}

class _ServiceStaffPopupState extends State<ServiceStaffPopup> {
  final TextEditingController _invoiceController = TextEditingController();
  final GlobalKey _key = GlobalKey();
  bool _showPopup = false;
  bool _showError = false;

  void _togglePopup() {
    setState(() {
      _showPopup = !_showPopup;
      _showError = false;
    });
  }

  void _sendInvoiceNo() {
    if (_invoiceController.text.isEmpty) {
      setState(() {
        _showError = true;
      });
    } else {
      // Handle the invoice number
      print('Invoice No: ${_invoiceController.text}');
      _togglePopup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _togglePopup,
      child: Stack(
        children: [
          Tooltip(
            message: 'Service Staff Replacement',
            child: Icon(Icons.person_add_alt_1_outlined),
          ),
          if (_showPopup)
            Positioned(
              top: 40,
              right: 0,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Service staff replacement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _invoiceController,
                        decoration: InputDecoration(
                          hintText: 'Invoice No.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _showError ? Colors.red : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _showError ? Colors.red : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _sendInvoiceNo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
