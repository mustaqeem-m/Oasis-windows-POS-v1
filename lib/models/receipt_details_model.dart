class ReceiptDetailsModel {
  final String? logo;
  final String? headerText;
  final String? displayName;
  final String? address;
  final String? contact;
  final String? taxId;
  final String? taxLabel1;
  final String? website;
  final String? email;
  final String? invoiceNoPrefix;
  final String? invoiceNo;
  final String? dateLabel;
  final String? invoiceDate;
  final String? customerLabel;
  final String? customerInfo;
  final String? salesPersonLabel;
  final String? salesPerson;
  final String? commissionAgentLabel;
  final String? commissionAgent;
  final String? totalItemsLabel;
  final String? totalItems;
  final String? totalQuantityLabel;
  final String? totalQuantity;
  final String? subtotalLabel;
  final String? subtotal;
  final String? taxLabel;
  final String? tax;
  final String? discountLabel;
  final String? discount;
  final String? shippingChargesLabel;
  final String? shippingCharges;
  final String? totalLabel;
  final String? total;
  final String? totalDueLabel;
  final String? totalDue;
  final String? totalPaidLabel;
  final String? totalPaid;
  final String? changeTenderedLabel;
  final String? changeTendered;
  final String? footerText;
  final bool showBarcode;
  final List<ReceiptLine> lines;
  final List<ReceiptPayment> payments;

  ReceiptDetailsModel({
    this.logo,
    this.headerText,
    this.displayName,
    this.address,
    this.contact,
    this.taxId,
    this.taxLabel1,
    this.website,
    this.email,
    this.invoiceNoPrefix,
    this.invoiceNo,
    this.dateLabel,
    this.invoiceDate,
    this.customerLabel,
    this.customerInfo,
    this.salesPersonLabel,
    this.salesPerson,
    this.commissionAgentLabel,
    this.commissionAgent,
    this.totalItemsLabel,
    this.totalItems,
    this.totalQuantityLabel,
    this.totalQuantity,
    this.subtotalLabel,
    this.subtotal,
    this.taxLabel,
    this.tax,
    this.discountLabel,
    this.discount,
    this.shippingChargesLabel,
    this.shippingCharges,
    this.totalLabel,
    this.total,
    this.totalDueLabel,
    this.totalDue,
    this.totalPaidLabel,
    this.totalPaid,
    this.changeTenderedLabel,
    this.changeTendered,
    this.footerText,
    this.showBarcode = false,
    required this.lines,
    required this.payments,
  });
}

class ReceiptLine {
  final String name;
  final String? subSku;
  final String quantity;
  final String units;
  final String unitPrice;
  final String unitPriceIncTax;
  final String discount;
  final String tax;
  final String? variation;
  final String? unitPriceBeforeDiscount;
  final String? totalLineDiscount;
  final String? mrp;

  ReceiptLine({
    required this.name,
    this.subSku,
    required this.quantity,
    required this.units,
    required this.unitPrice,
    required this.unitPriceIncTax,
    required this.discount,
    required this.tax,
    this.variation,
    this.unitPriceBeforeDiscount,
    this.totalLineDiscount,
    this.mrp,
  });
}

class ReceiptPayment {
  final String method;
  final String date;
  final String amount;

  ReceiptPayment({
    required this.method,
    required this.date,
    required this.amount,
  });
}
