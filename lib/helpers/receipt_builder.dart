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
      format = PdfPageFormat(72.1 * PdfPageFormat.mm, double.infinity, marginAll: 0);
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
                pw.Text(details.address!, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9)),
              if (details.contact != null)
                pw.Text(details.contact!, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Divider(height: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.invoiceNoPrefix ?? 'Invoice No:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.Text(details.invoiceNo ?? '', style: pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.dateLabel ?? 'Date:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.Text(details.invoiceDate ?? '', style: pw.TextStyle(fontSize: 9)),
          ],
        ),
        if (details.customerInfo != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.customerLabel ?? 'Customer:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(details.customerInfo!, style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        pw.Divider(height: 1),
        pw.SizedBox(height: 3),

        // Item Table
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600))),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
            4: const pw.FlexColumnWidth(3),
          },
          headers: ['#', 'Item', 'Qty', 'Price', 'Total'],
          data: List<List<String>>.generate(
            details.lines.length,
            (index) {
              final line = details.lines[index];
              return [
                (index + 1).toString(),
                '${line.name} ${line.variation ?? ''}',
                '${line.quantity} ${line.units}',
                line.unitPriceIncTax,
                line.lineTotal,
              ];
            },
          ),
        ),
        pw.Divider(height: 1),
        pw.SizedBox(height: 3),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(details.subtotalLabel ?? 'Subtotal:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.Text(details.subtotal ?? '',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          ],
        ),
        if (details.discount != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.discountLabel ?? 'Discount:', style: pw.TextStyle(fontSize: 9)),
              pw.Text('(-) ${details.discount}', style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        if (details.tax != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.taxLabel ?? 'Tax:', style: pw.TextStyle(fontSize: 9)),
              pw.Text('(+) ${details.tax}', style: pw.TextStyle(fontSize: 9)),
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
                  pw.Text('${p.method} (${p.date})', style: pw.TextStyle(fontSize: 9)),
                  pw.Text(p.amount, style: pw.TextStyle(fontSize: 9)),
                ],
              )),

        // Total Due
        if (details.totalDue != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(details.totalDueLabel ?? 'Total Due:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(details.totalDue!,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ],
          ),

        pw.SizedBox(height: 8),

        // Footer
        if (details.footerText != null)
          pw.Center(
              child:
                  pw.Text(details.footerText!, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8))),

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
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '    ${line.quantity} ${line.units} x ${line.unitPriceBeforeDiscount ?? line.unitPriceIncTax}',
                    ),
                    pw.Text(line.lineTotal),
                  ],
                ),
                if (line.totalLineDiscount != null &&
                    line.totalLineDiscount != '0.00')
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('Discount: (-) ${line.totalLineDiscount}'),
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
    // TODO: Implement the 3-inch alternate layout (from slim3.blade.php)
    return pw.Center(
        child: pw.Text("Alternate 3-inch Receipt (slim3.blade.php)"));
  }
}
