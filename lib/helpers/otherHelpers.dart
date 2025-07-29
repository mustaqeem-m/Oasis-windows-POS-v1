import 'dart:io';
import 'dart:typed_data';

import 'package:pos_2/apis/user.dart';

import '../components/barcode_scanner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// import 'package:call_log/call_log.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_2/models/contact_model.dart';
import 'package:pos_2/models/paymentDatabase.dart';
import 'package:pos_2/models/receipt_details_model.dart';
import 'package:pos_2/models/sellDatabase.dart';
import 'package:pos_2/providers/home_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
// import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../locale/MyLocalizations.dart';
import '../models/invoice.dart';
import '../models/system.dart';
import 'AppTheme.dart';
import 'SizeConfig.dart';
import 'receipt_builder.dart';

class Helper {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  Widget loadingIndicator(context) {
    return Center(
      child: Card(
        elevation: MySize.size10,
        child: Container(
          padding: EdgeInsets.all(MySize.size28!),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MySize.size8!),
          ),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  //format currency
  String formatCurrency(amount) {
    double convertAmount = double.parse(amount.toString());

    var amt = NumberFormat.currency(
            symbol: '', decimalDigits: Config.currencyPrecision)
        .format(convertAmount);
    return amt;
  }

  double validateInput(String val) {
    try {
      double value = double.parse(val.toString());
      return value;
    } catch (e) {
      return 0.00;
    }
  }

  //format quantity
  String formatQuantity(amount) {
    double quantity = double.parse(amount.toString());
    var amt = NumberFormat.currency(
            symbol: '', decimalDigits: Config.quantityPrecision)
        .format(quantity);
    return amt;
  }

  //argument model
  Map argument(
      {int? sellId,
      int? locId,
      int? taxId,
      String? discountType,
      double? discountAmount,
      double? invoiceAmount,
      int? customerId,
      int? isQuotation,
      int? serviceStaff}) {
    Map args = {
      'sellId': sellId,
      'locationId': locId,
      'taxId': taxId,
      'discountType': discountType,
      'discountAmount': discountAmount,
      'invoiceAmount': invoiceAmount,
      'customerId': customerId,
      'is_quotation': isQuotation,
      'serviceStaff': serviceStaff
    };
    return args;
  }

  //check internet connectivity
  Future<bool> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  //get location name by location_id
  Future<String?> getLocationNameById(var id) async {
    String? locationName;
    var response = await System().get('location');
    response.forEach((element) {
      if (element['id'] == int.parse(id.toString())) {
        locationName = element['name'];
      }
    });
    return locationName;
  }

  //calculate inline tax and discount amount
  calculateTaxAndDiscount(
      {discountAmount, discountType, taxId, unitPrice}) async {
    double disAmt = 0.0, tax = 0.00, taxAmt = 0.00;
    await System().get('tax').then((value) {
      value.forEach((element) {
        if (element['id'] == taxId) {
          tax = double.parse(element['amount'].toString()) * 1.0;
        }
      });
    });

    if (discountType == 'fixed') {
      disAmt = discountAmount;
      taxAmt = ((unitPrice - discountAmount) * tax / 100);
    } else {
      disAmt = (unitPrice * discountAmount / 100);
      taxAmt = ((unitPrice - (unitPrice * discountAmount / 100)) * tax / 100);
    }
    return {'discountAmount': disAmt, 'taxAmount': taxAmt};
  }

  //calculate price including tax
  calculateTotal({unitPrice, discountType, discountAmount, taxId}) async {
    double tax = 0.00;
    double subTotal = 0.00;
    double amount = 0.0;
    unitPrice = double.parse(unitPrice.toString());
    discountAmount = double.parse(discountAmount.toString());
    //set tax
    await System().get('tax').then((value) {
      value.forEach((element) {
        if (element['id'] == taxId) {
          tax = double.parse(element['amount'].toString()) * 1.0;
        }
      });
    });
    //calculate subTotal according to discount type
    if (discountType == 'fixed') {
      amount = unitPrice - discountAmount;
    } else {
      amount = unitPrice - (unitPrice * discountAmount / 100);
    }
    //calculate subtotal
    subTotal = (amount + (amount * tax / 100));
    return subTotal.toStringAsFixed(2);
  }

  Future<String> barcodeScan(BuildContext context) async {
    var result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerPage(),
        ));
    return result ?? "";
  }

  Future<ReceiptDetailsModel> _mapSellToReceiptDetails(
      int sellId, BuildContext context) async {
    final sell = (await SellDatabase().getSellBySellId(sellId)).first;
    final sellLines = await SellDatabase().getSellLines(sellId);
    final payments = await PaymentDatabase().get(sellId);
    final business = (await System().get('business')).first;
    final user = sell['service_staff_id'] != null
        ? await User().get(sell['service_staff_id'])
        : null;

    double totalQuantity = 0;
    List<ReceiptLine> receiptLines = [];
    for (var line in sellLines) {
      final quantity = (line['quantity'] as num?) ?? 0;
      final unitPrice = (line['unit_price'] as num?) ?? 0;
      final unitPriceIncTax = (line['unit_price_inc_tax'] as num?) ?? 0;
      final taxAmount = (line['tax_amount'] as num?) ?? 0;
      final discountAmount = (line['line_discount_amount'] as num?) ?? 0;

      totalQuantity += quantity;
      receiptLines.add(ReceiptLine(
        name: line['product_name'],
        subSku: line['sub_sku'],
        quantity: quantity.toString(),
        units: line['unit'] ?? '',
        unitPrice: unitPrice.toString(),
        unitPriceIncTax: unitPriceIncTax.toString(),
        discount: discountAmount.toString(),
        tax: taxAmount.toString(),
        variation: line['product_variation_name'],
        unitPriceBeforeDiscount: line['default_sell_price'].toString(),
        totalLineDiscount: line['line_discount_amount'].toString(),
        mrp: line['mrp'].toString(),
      ));
    }

    List<ReceiptPayment> receiptPayments = [];
    double totalPaid = 0;
    for (var p in payments) {
      final amount = (p['amount'] as num?) ?? 0;
      totalPaid += amount;
      receiptPayments.add(ReceiptPayment(
        method: p['method'],
        date: DateFormat('MM-dd')
            .format(DateTime.parse(p['paid_on'] ?? DateTime.now().toString())),
        amount: amount.toString(),
      ));
    }

    final contact = await Contact().getCustomerDetailById(sell['contact_id']);
    final commissionAgent = sell['commission_agent'] != null
        ? await User().get(sell['commission_agent'])
        : null;
    final businessContacts = await System().get('contact_no');
    final businessContact =
        businessContacts.isNotEmpty ? businessContacts.first : null;

    return ReceiptDetailsModel(
      logo: 'assets/images/oasis_pos_logo_.1-1.png',
      headerText: 'Tax Invoice',
      displayName: business['name'],
      address: business['address'],
      contact: businessContact,
      taxId: business['tax_number_1'],
      taxLabel1: business['tax_label_1'],
      website: business['website'],
      email: business['email'],
      invoiceNoPrefix: 'Invoice No:',
      invoiceNo: sell['invoice_no'],
      dateLabel: 'Date:',
      invoiceDate: DateFormat('yyyy-MM-dd HH:mm').format(
          DateTime.parse(sell['transaction_date'] ?? DateTime.now().toString())),
      customerLabel: 'Customer:',
      customerInfo: contact != null ? contact['name'] : 'Walk-in Customer',
      salesPersonLabel: 'Sales Man:',
      salesPerson:
          user != null ? '${user['first_name']} ${user['last_name']}' : '',
      commissionAgentLabel: 'Commission Agent:',
      commissionAgent: commissionAgent != null
          ? '${commissionAgent['first_name']} ${commissionAgent['last_name']}'
          : '',
      totalItemsLabel: 'Total Items:',
      totalItems: sellLines.length.toString(),
      totalQuantityLabel: 'Total Quantity:',
      totalQuantity: totalQuantity.toString(),
      subtotalLabel: 'Subtotal:',
      subtotal: formatCurrency(sell['total_before_tax'] ?? 0.0),
      taxLabel: 'Tax:',
      tax: formatCurrency(sell['tax_amount'] ?? 0.0),
      discountLabel: 'Discount:',
      discount: formatCurrency(sell['discount_amount'] ?? 0.0),
      shippingChargesLabel: 'Shipping Charges:',
      shippingCharges: formatCurrency(sell['shipping_charges'] ?? 0.0),
      totalLabel: 'Total:',
      total: formatCurrency(sell['invoice_amount'] ?? 0.0),
      totalDueLabel: 'Total Due:',
      totalDue: formatCurrency(sell['pending_amount'] ?? 0.0),
      totalPaidLabel: 'Paid Amount:',
      totalPaid: formatCurrency(totalPaid),
      changeTenderedLabel: 'Change Tendered:',
      changeTendered: formatCurrency(sell['change_return'] ?? 0.0),
      footerText: 'Thank you for your business!',
      showBarcode: true,
      lines: receiptLines,
      payments: receiptPayments,
    );
  }

  Future<void> printDocument(sellId, taxId, context, {invoice}) async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final paperSize = homeProvider.selectedPaperSize;
    final printer = homeProvider.selectedPrinter;

    final receiptDetails = await _mapSellToReceiptDetails(sellId, context);
    final receiptBuilder = ReceiptBuilder();
    final Uint8List pdfBytes =
        await receiptBuilder.buildReceiptPdf(paperSize, receiptDetails);

    if (printer != null) {
      await Printing.directPrintPdf(
          printer: printer, onLayout: (PdfPageFormat format) async => pdfBytes);
    } else {
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes);
    }
  }

  // //request permissions
  requestAppPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.storage,
      Permission.camera,
      // Permission.phone
    ].request();
    return statuses;
  }

  //job scheduler
  jobScheduler() {
    if (Config().syncCallLog) {
      final cron = Cron();
      cron.schedule(Schedule.parse('*/${Config.callLogSyncDuration} * * * *'),
          () async {
        syncCallLogs();
      });
    }
  }

  //post call_logs in api
  syncCallLogs() async {
    if (await Permission.phone.status == PermissionStatus.granted) {
      if (Config().syncCallLog && await Helper().checkConnectivity()) {
        // ignore: unused_local_variable
        List recentLogs = [];
        //get last sync time
        var lastSync = await System().callLogLastSyncDateTime();
        //difference between time now and last sync
        int getLogBefore = (lastSync != null)
            ? DateTime.now().difference(DateTime.parse(lastSync)).inMinutes
            : 1440;
        //set 'from' duration for call_log query
        // ignore: unused_local_variable
        int from = DateTime.now()
            .subtract(
                Duration(minutes: (getLogBefore > 1440) ? 1440 : getLogBefore))
            .millisecondsSinceEpoch;
        try {
          // //fetch call_log
          // await CallLog.query(dateFrom: from).then((value) async {
          //   if (value.isNotEmpty) {
          //     value.forEach((element) {
          //       recentLogs.add(CallLogModel().createLog(element));
          //     });
          //     //     //save call_log in api
          //     await FollowUpApi()
          //         .syncCallLog({'call_logs': recentLogs}).then((value) async {
          //       if (value == true) {
          //         System().callLogLastSyncDateTime(true);
          //       }
          //     });
          //   }
          // });
        } catch (e) {}
      }
    }
  }

  //share invoice
  // savePdf(sellId, taxId, context, invoiceNo, {invoice}) async {
  //   String _invoice = (invoice != null)
  // ? invoice
  //       : await InvoiceFormatter().generateInvoice(sellId, taxId, context);
  //   var targetPath = await getTemporaryDirectory();
  //   var targetFileName = "invoice_no: ${Random().nextInt(100)}";

  //   var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
  //       _invoice, targetPath.path, targetFileName);

  //   await Share.shareFiles([generatedPdfFile.path]);
  //   //to get file path use generatedPdfFile.path
  // }

  //share invoice
  // savePdf(sellId, taxId, context, invoiceNo, {invoice}) async {
  //   String _invoice = (invoice != null)
  //       ?  invoice
  //       : await InvoiceFormatter().generateInvoice(sellId, taxId, context);

  //   final pdf = pw.Document();

  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) {
  //         return pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             pw.Text('Invoice - $invoiceNo',
  //                 style: pw.TextStyle(
  //                     fontSize: 18, fontWeight: pw.FontWeight.bold)),
  //             pw.SizedBox(height: 16),
  //             pw.Text(_invoice), // raw HTML text output, optional parsing
  //           ],
  //         );
  //       },
  //     ),
  //   );

  //   final outputDir = await getTemporaryDirectory();
  //   final fileName = "invoice_no_${Random().nextInt(100)}.pdf";
  //   final filePath = "${outputDir.path}/$fileName";

  //   final file = File(filePath);
  //   await file.writeAsBytes(await pdf.save());

  //   await Share.shareXFiles([XFile(file.path)],
  //       text: 'Invoice - $invoiceNo');
  // }

  Future<String> savePdf(sellId, taxId, context, invoiceNo, {invoice}) async {
    // Step 1: Generate invoice HTML if not provided
    String _invoice = (invoice != null)
        ? invoice
        : await InvoiceFormatter().generateInvoice(sellId, taxId, context);

    // Step 2: Convert HTML to PDF bytes (forced to A4 size)
    final pdfBytes = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: _invoice,
    );

    // Step 3: Get system's temporary directory
    final dir = await getTemporaryDirectory();

    // Step 4: Define file path and create file
    final filePath = '${dir.path}/Invoice_$invoiceNo.pdf';
    final file = File(filePath);

    // Step 5: Save the bytes to the file
    await file.writeAsBytes(pdfBytes);

    // Step 6: Return file path (useful for sharing/opening later)
    return filePath;
  }

  //fetch formatted business details
  Future<Map<String, dynamic>> getFormattedBusinessDetails() async {
    List business = await System().get('business');
    if (business.isEmpty) {
      return {
        'symbol': '₹',
        'name': 'Business Name',
        'logo': Config().defaultBusinessImage,
        'currencyPrecision': Config.currencyPrecision,
        'quantityPrecision': Config.quantityPrecision,
        'taxLabel': '',
        'taxNumber': '',
        'enabledModules': [],
        'posSettings': []
      };
    }
    String? symbol = '₹',
        name = business[0]['name'],
        logo = business[0]['logo'],
        taxLabel = business[0]['tax_label_1'],
        taxNumber = business[0]['tax_number_1'];
    List enabledModules = business[0]['enabled_modules'];
    Map<String, dynamic>? posSettings = business[0]['pos_settings'];
    int? currencyPrecision = (business[0]['currency_precision'] != null)
            ? int.parse(business[0]['currency_precision'].toString())
            : Config.currencyPrecision,
        quantityPrecision = (business[0]['quantity_precision'] != null)
            ? int.parse(business[0]['quantity_precision'].toString())
            : Config.quantityPrecision;
    return {
      'symbol': symbol ?? '',
      'name': name ?? '',
      'logo': logo ?? Config().defaultBusinessImage,
      'currencyPrecision': currencyPrecision,
      'quantityPrecision': quantityPrecision,
      'taxLabel': (taxLabel != null) ? '$taxLabel : ' : '',
      'taxNumber': (taxNumber != null) ? '$taxNumber' : '',
      'enabledModules': (enabledModules.isNotEmpty) ? enabledModules : [],
      'posSettings':
          (posSettings != null && posSettings.isNotEmpty) ? posSettings : []
    };
  }

  //Fetch permission from database
  Future<bool> getPermission(String permissionFor) async {
    bool permission = false;
    await System().getPermission().then((value) {
      if ((value.isNotEmpty && value[0] == 'all') ||
          value.contains(permissionFor)) {
        permission = true;
      }
    });
    return permission;
  }

  //call widget
  Widget callDropdown(context, followUpDetails, List numbers,
      {required String type}) {
    numbers.removeWhere((element) => element.toString() == 'null');
    return Container(
      height: MySize.size36,
      child: PopupMenuButton<String>(
        icon: Icon(
          (type == 'call') ? MdiIcons.phone : MdiIcons.whatsapp,
          color:
              (type == 'call') ? themeData.colorScheme.primary : Colors.green,
        ),
        onSelected: (value) async {
          if (type == 'call') {
            await launch('tel:$value');
          }

          if (type == 'whatsApp') {
            await launch("https://wa.me/$value");
          }
        },
        itemBuilder: (BuildContext context) {
          return numbers.map((item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(
                '$item',
                style: TextStyle(color: Colors.black),
              ),
            );
          }).toList();
        },
      ),
    );
  }

  //noData widget
  noDataWidget(context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: CachedNetworkImage(
            imageUrl: Config().noDataImage,
            errorWidget: (context, url, error) =>
                Image.asset('assets/images/noData.png'),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            AppLocalizations.of(context).translate('no_data'),
            style: AppTheme.getTextStyle(
              themeData.textTheme.headlineSmall,
              fontWeight: 600,
              color: themeData.colorScheme.onSurface,
            ),
          ),
        )
      ],
    );
  }
}
