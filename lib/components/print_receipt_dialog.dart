import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintReceiptDialog extends StatefulWidget {
  final int sellId;
  final List<dynamic> printers;
  final int? selectedPrinterId;
  final Map<String, dynamic> saleDetails;
  final List<Map<String, dynamic>> sellLines;
  final List<dynamic> payment;

  const PrintReceiptDialog({
    super.key,
    required this.sellId,
    required this.printers,
    this.selectedPrinterId,
    required this.saleDetails,
    required this.sellLines,
    required this.payment,
  });

  @override
  State<PrintReceiptDialog> createState() => _PrintReceiptDialogState();
}

class _PrintReceiptDialogState extends State<PrintReceiptDialog> {
  int? _selectedPrinterId;
  int _copies = 1;
  String _paperSize = 'A4';

  @override
  void initState() {
    super.initState();
    _selectedPrinterId = widget.selectedPrinterId;
  }

  Future<void> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return _buildPdfReceipt();
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'receipt_${widget.saleDetails['invoice_no'] ?? widget.sellId}.pdf',
      format: format,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Print Receipt'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Row(
          children: [
            // Receipt Preview
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: _buildReceiptPreview(),
              ),
            ),
            // Print Settings
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Print Settings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text('Printer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedPrinterId,
                      items: widget.printers.map((printer) {
                        return DropdownMenuItem<int>(
                          value: printer['id'],
                          child: Text(printer['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPrinterId = value;
                        });
                      },
                      hint: const Text("Select Printer"),
                    ),
                    const SizedBox(height: 24),
                    const Text('Copies',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_copies > 1) {
                              setState(() {
                                _copies--;
                              });
                            }
                          },
                        ),
                        Text('$_copies'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _copies++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Paper Size',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _paperSize,
                      items: ['A4', 'Letter', 'Legal'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _paperSize = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final format = _paperSize == 'Letter'
                ? PdfPageFormat.letter
                : _paperSize == 'Legal'
                    ? PdfPageFormat.legal
                    : PdfPageFormat.a4;
            _generatePdf(format);
            Navigator.of(context).pop();
          },
          child: const Text('Print'),
        ),
      ],
    );
  }

  Widget _buildReceiptPreview() {
    final totalAmount = widget.saleDetails['invoice_amount'] ?? 0.0;
    final discount = widget.saleDetails['discount_amount'] ?? 0.0;
    final subtotal = totalAmount + discount;
    final paid = widget.payment.fold<double>(
        0.0, (sum, item) => sum + ((item['amount'] as num?) ?? 0.0));
    final change = paid - totalAmount > 0 ? paid - totalAmount : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
              child: Text('Oasis POS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          Text('Invoice No: ${widget.saleDetails['invoice_no'] ?? ''}'),
          Text(
              'Date: ${widget.saleDetails['transaction_date'] != null ? DateFormat.yMd().add_jm().format(DateTime.parse(widget.saleDetails['transaction_date'])) : ''}'),
          const SizedBox(height: 16),
          const Divider(),
          DataTable(
            columns: const [
              DataColumn(label: Text('Item')),
              DataColumn(label: Text('Qty'), numeric: true),
              DataColumn(label: Text('Price'), numeric: true),
              DataColumn(label: Text('Total'), numeric: true),
            ],
            rows: widget.sellLines.map((line) {
              final unitPrice = line['unit_price'] ?? 0.0;
              final quantity = line['quantity'] ?? 0.0;
              final total = unitPrice * quantity;
              return DataRow(cells: [
                DataCell(Text(line['product_name'] ?? 'N/A')),
                DataCell(Text(quantity.toString())),
                DataCell(Text(unitPrice.toStringAsFixed(2))),
                DataCell(Text(total.toStringAsFixed(2))),
              ]);
            }).toList(),
          ),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
                  Text('Discount: ${discount.toStringAsFixed(2)}'),
                  Text('Total: ${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Paid: ${paid.toStringAsFixed(2)}'),
                  Text('Change: ${change.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfReceipt() {
    final totalAmount = widget.saleDetails['invoice_amount'] ?? 0.0;
    final discount = widget.saleDetails['discount_amount'] ?? 0.0;
    final subtotal = totalAmount + discount;
    final paid = widget.payment.fold<double>(
        0.0, (sum, item) => sum + ((item['amount'] as num?) ?? 0.0));
    final change = paid - totalAmount > 0 ? paid - totalAmount : 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
            child: pw.Text('Oasis POS',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 16),
        pw.Text('Invoice No: ${widget.saleDetails['invoice_no'] ?? ''}'),
        pw.Text(
            'Date: ${widget.saleDetails['transaction_date'] != null ? DateFormat.yMd().add_jm().format(DateTime.parse(widget.saleDetails['transaction_date'])) : ''}'),
        pw.SizedBox(height: 16),
        pw.Divider(),
        pw.Table.fromTextArray(
          headers: ['Item', 'Qty', 'Price', 'Total'],
          data: widget.sellLines.map((line) {
            final unitPrice = line['unit_price'] ?? 0.0;
            final quantity = line['quantity'] ?? 0.0;
            final total = unitPrice * quantity;
            return [
              line['product_name'] ?? 'N/A',
              quantity.toString(),
              unitPrice.toStringAsFixed(2),
              total.toStringAsFixed(2),
            ];
          }).toList(),
        ),
        pw.Divider(),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
                pw.Text('Discount: ${discount.toStringAsFixed(2)}'),
                pw.Text('Total: ${totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Paid: ${paid.toStringAsFixed(2)}'),
                pw.Text('Change: ${change.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
