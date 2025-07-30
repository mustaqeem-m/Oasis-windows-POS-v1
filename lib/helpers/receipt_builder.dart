import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/receipt_details_model.dart';

class ReceiptBuilder {
  Future<Uint8List> buildReceiptPdf(
      String paperSize, ReceiptDetailsModel details) async {
    final pdf = pw.Document();

    // Determine page format based on paper size
    final PdfPageFormat format;
    if (paperSize == '2-inch') {
      // 58mm paper width, leaving some margin
      format = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity,
          marginAll: 2 * PdfPageFormat.mm);
    } else {
      // 80mm paper with 72.1mm printable area
      format =
          PdfPageFormat(72.1 * PdfPageFormat.mm, double.infinity, marginAll: 0);
    }

    // Load logo image
    final logoImage = details.logo != null
        ? pw.MemoryImage(
            (await rootBundle.load(details.logo!)).buffer.asUint8List())
        : null;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          if (paperSize == '2-inch') {
            return _buildSlim2Layout(details, logoImage);
          } else if (paperSize == '3-inch-alt') {
            return _buildSlim3Layout(details, logoImage);
          } else {
            return _buildSlim1Layout(details, logoImage);
          }
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSlim1Layout(
      ReceiptDetailsModel details, pw.ImageProvider? logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        if (logo != null) pw.Center(child: pw.Image(logo, height: 35)),
        pw.Center(
          child: pw.Column(
            children: [
              if (details.headerText != null)
                pw.Text(details.headerText!,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
              if (details.displayName != null)
                pw.Text(details.displayName!,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
              if (details.address != null)
                pw.Text(details.address!,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9)),
              if (details.contact != null)
                pw.Text(details.contact!,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9)),
              if (details.taxId != null)
                pw.Text('Tax ID: ${details.taxId}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9)),
              if (details.website != null)
                pw.Text('Website: ${details.website}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9)),
              if (details.email != null)
                pw.Text('Email: ${details.email}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Divider(height: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.invoiceNoPrefix ?? 'Invoice No:',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.Text(details.invoiceNo ?? '', style: pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.dateLabel ?? 'Date:',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.Text(details.invoiceDate ?? '',
                style: pw.TextStyle(fontSize: 9)),
          ],
        ),
        if (details.customerInfo != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.customerLabel ?? 'Customer:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(details.customerInfo!, style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        if (details.salesPerson != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.salesPersonLabel ?? 'Sales Man:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(details.salesPerson!, style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        pw.Divider(height: 1),
        pw.SizedBox(height: 3),

        // Item Table
        pw.Table.fromTextArray(
          headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600))),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(7),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
          },
          headers: ['#', 'Item & SKU', 'Qty', 'Unit Price'],
          data: List<List<String>>.generate(
            details.lines.length,
            (index) {
              final line = details.lines[index];
              return [
                (index + 1).toString(),
                '${line.name} (${line.subSku ?? ''})',
                '${line.quantity} ${line.units}',
                line.unitPrice,
              ];
            },
          ),
        ),
        // pw.Divider(height: 1),
        pw.SizedBox(height: 3),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                '${details.totalItemsLabel} ${details.totalItems} | ${details.totalQuantityLabel} ${details.totalQuantity}',
                style: pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.subtotalLabel ?? 'Subtotal:',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.Text(details.subtotal ?? '',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          ],
        ),
        if (details.discount != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.discountLabel ?? 'Discount:',
                  style: pw.TextStyle(fontSize: 9)),
              pw.Text('(-) ${details.discount}',
                  style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        if (details.tax != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.taxLabel ?? 'Tax:',
                  style: pw.TextStyle(fontSize: 9)),
              pw.Text('(+) ${details.tax}', style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        if (details.shippingCharges != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.shippingChargesLabel ?? 'Shipping Charges:',
                  style: pw.TextStyle(fontSize: 9)),
              pw.Text('(+) ${details.shippingCharges}',
                  style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        pw.Divider(height: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.totalLabel ?? 'Total:',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(details.total ?? '',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ],
        ),
        pw.Divider(height: 1),

        // Payments
        if (details.payments.isNotEmpty)
          ...details.payments.map((p) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${p.method} (${p.date})',
                      style: pw.TextStyle(fontSize: 9)),
                  pw.Text(p.amount, style: pw.TextStyle(fontSize: 9)),
                ],
              )),

        // Total Due
        if (details.totalDue != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.totalDueLabel ?? 'Total Due:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(details.totalDue!,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ],
          ),
        if (details.totalPaid != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.totalPaidLabel ?? 'Paid Amount:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(details.totalPaid!,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ],
          ),
        if (details.changeTendered != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.changeTenderedLabel ?? 'Change Tendered:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(details.changeTendered!,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ],
          ),

        pw.SizedBox(height: 8),

        // Footer
        if (details.footerText != null)
          pw.Center(
              child: pw.Text(details.footerText!,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 8))),

        pw.SizedBox(height: 4),

        // Barcode
        if (details.showBarcode && details.invoiceNo != null)
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: details.invoiceNo!,
              height: 35,
              width: 90,
            ),
          ),
      ],
    );
  }

  pw.Widget _buildSlim2Layout(
      ReceiptDetailsModel details, pw.ImageProvider? logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Header
        if (logo != null) pw.Image(logo, height: 60),
        if (details.headerText != null)
          pw.Text(details.headerText!,
              textAlign: pw.TextAlign.center,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        if (details.displayName != null)
          pw.Text(details.displayName!,
              textAlign: pw.TextAlign.center,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        if (details.address != null)
          pw.Text(details.address!, textAlign: pw.TextAlign.center),
        if (details.contact != null)
          pw.Text(details.contact!, textAlign: pw.TextAlign.center),
        if (details.website != null)
          pw.Text(details.website!, textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 5),

        // Invoice Info
        pw.Divider(thickness: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.invoiceNoPrefix ?? 'Invoice No:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(details.invoiceNo ?? ''),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.dateLabel ?? 'Date:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(details.invoiceDate ?? ''),
          ],
        ),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),

        // Customer Info
        if (details.customerInfo != null)
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(details.customerLabel ?? 'Customer:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(details.customerInfo!),
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1),
          ]),

        // Item Lines
        pw.Column(
          children: List.generate(details.lines.length, (index) {
            final line = details.lines[index];
            return pw.Column(
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '#${index + 1}. ${line.name} ${line.variation ?? ''}',
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text(
                      '    ${line.quantity} ${line.units} x ${line.unitPriceBeforeDiscount ?? line.unitPriceIncTax}',
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Divider(borderStyle: pw.BorderStyle.dotted),
              ],
            );
          }),
        ),

        pw.SizedBox(height: 5),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.subtotalLabel ?? 'Subtotal:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(details.subtotal ?? '',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
        if (details.discount != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.discountLabel ?? 'Discount:'),
              pw.Text('(-) ${details.discount}'),
            ],
          ),
        if (details.tax != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.taxLabel ?? 'Tax:'),
              pw.Text('(+) ${details.tax}'),
            ],
          ),
        if (details.shippingCharges != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.shippingChargesLabel ?? 'Shipping:'),
              pw.Text('(+) ${details.shippingCharges}'),
            ],
          ),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.totalLabel ?? 'Total:',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.Text(details.total ?? '',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          ],
        ),
        pw.Divider(),

        // Payments
        if (details.payments.isNotEmpty)
          ...details.payments.map((p) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${p.method} (${p.date})'),
                  pw.Text(p.amount),
                ],
              )),

        // Total Due
        if (details.totalDue != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.totalDueLabel ?? 'Total Due:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(details.totalDue!,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),

        pw.SizedBox(height: 10),

        // Footer
        if (details.footerText != null)
          pw.Text(details.footerText!, textAlign: pw.TextAlign.center),

        // Barcode
        if (details.showBarcode && details.invoiceNo != null)
          pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: details.invoiceNo!,
            height: 50,
          ),
      ],
    );
  }

  pw.Widget _buildSlim3Layout(
      ReceiptDetailsModel details, pw.ImageProvider? logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        if (logo != null)
          pw.Center(child: pw.Image(logo, height: 40, fit: pw.BoxFit.contain)),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Column(
            children: [
              if (details.displayName != null)
                pw.Text(details.displayName!,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
              if (details.address != null)
                pw.Text(details.address!,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9)),
              if (details.contact != null)
                pw.Text(details.contact!,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9)),
              if (details.taxId != null)
                pw.Text('${details.taxLabel1 ?? 'Tax ID'}: ${details.taxId}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        pw.Divider(
            height: 1, thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

        // Invoice Info
        _buildInfoRow(
            details.invoiceNoPrefix ?? 'Invoice No:', details.invoiceNo ?? ''),
        _buildInfoRow(details.dateLabel ?? 'Date:', details.invoiceDate ?? ''),
        if (details.salesPerson != null && details.salesPerson!.isNotEmpty)
          _buildInfoRow(details.salesPersonLabel ?? 'Sales Person:',
              details.salesPerson!),
        if (details.commissionAgent != null &&
            details.commissionAgent!.isNotEmpty)
          _buildInfoRow(details.commissionAgentLabel ?? 'Commission Agent:',
              details.commissionAgent!),

        // Customer Info
        pw.Divider(
            height: 1, thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(details.customerLabel ?? 'Customer:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        ),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(details.customerInfo ?? '',
              style: pw.TextStyle(fontSize: 9)),
        ),
        pw.Divider(
            height: 1, thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 3),

        // Item Table
        pw.Table.fromTextArray(
          headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          cellStyle: const pw.TextStyle(fontSize: 7.5),
          cellPadding: pw.EdgeInsets.symmetric(vertical: 2),
          headerDecoration: const pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600))),
          columnWidths: {
            0: const pw.FlexColumnWidth(7), // Description
            1: const pw.FlexColumnWidth(2), // Qty
            2: const pw.FlexColumnWidth(3), // Rate
          },
          headers: ['Item & SKU', 'Qty', 'Rate'],
          data: List<List<String>>.generate(
            details.lines.length,
            (index) {
              final line = details.lines[index];
              return [
                '${line.name} ${line.variation ?? ''} (${line.subSku ?? ''})',
                '${line.quantity} ${line.units}',
                line.unitPrice,
              ];
            },
          ),
        ),
        // pw.Divider(height: 1),
        pw.SizedBox(height: 5),

        // Totals
        _buildTotalRow(details.totalQuantityLabel ?? 'Total Quantity:',
            details.totalQuantity ?? ''),
        _buildTotalRow(details.totalItemsLabel ?? 'Total Items:',
            details.totalItems ?? ''),
        pw.SizedBox(height: 3),
        if (details.shippingCharges != null &&
            double.parse(details.shippingCharges!) > 0)
          _buildTotalRow(details.shippingChargesLabel ?? 'Shipping:',
              details.shippingCharges!),
        if (details.discount != null && double.parse(details.discount!) > 0)
          _buildTotalRow(
              details.discountLabel ?? 'Discount:', '(-) ${details.discount!}'),
        if (details.tax != null && double.parse(details.tax!) > 0)
          _buildTotalRow(details.taxLabel ?? 'Tax:', '(+) ${details.tax!}'),

        pw.Divider(height: 1),
        _buildTotalRow(details.totalLabel ?? 'Total:', details.total ?? '',
            isHeader: true),
        pw.Divider(height: 1),

        // Payments
        if (details.payments.isNotEmpty)
          ...details.payments
              .map((p) => _buildTotalRow('${p.method} (${p.date})', p.amount)),

        // Total Due
        if (details.totalDue != null && double.parse(details.totalDue!) > 0)
          _buildTotalRow(
              details.totalDueLabel ?? 'Total Due:', details.totalDue!),

        pw.SizedBox(height: 10),

        // Footer & Barcode
        if (details.footerText != null)
          pw.Center(
              child: pw.Text(details.footerText!,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 8))),
        pw.SizedBox(height: 5),
        if (details.showBarcode && details.invoiceNo != null)
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: details.invoiceNo!,
              height: 40,
            ),
          ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String value,
      {bool isHeader = false}) {
    final style = isHeader
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)
        : pw.TextStyle(fontSize: 9);
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
