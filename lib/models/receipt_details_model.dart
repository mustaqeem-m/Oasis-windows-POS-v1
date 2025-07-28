class ReceiptDetailsModel {
  final String? logo;
  final String? headerText;
  final String? displayName;
  final String? address;
  final String? contact;
  final String? website;
  final String? locationCustomFields;
  final String? subHeadingLine1;
  final String? subHeadingLine2;
  final String? subHeadingLine3;
  final String? subHeadingLine4;
  final String? subHeadingLine5;
  final String? taxLabel1;
  final String? taxInfo1;
  final String? taxLabel2;
  final String? taxInfo2;
  final String? invoiceHeading;
  final String? letterHead;
  final String? invoiceNoPrefix;
  final String? invoiceNo;
  final String? dateLabel;
  final String? invoiceDate;
  final String? dueDateLabel;
  final String? dueDate;
  final String? salesPersonLabel;
  final String? salesPerson;
  final String? commissionAgentLabel;
  final String? commissionAgent;
  final String? customerLabel;
  final String? customerInfo;
  final String? clientIpLabel;
  final String? clientIp;
  final String? customerTaxLabel;
  final String? customerTaxNumber;
  final String? customerCustomFields;
  final String? customerRpLabel;
  final String? customerTotalRp;
  final String? totalQuantityLabel;
  final String? totalQuantity;
  final String? totalItemsLabel;
  final String? totalItems;
  final String? subtotalLabel;
  final String? subtotal;
  final String? shippingChargesLabel;
  final String? shippingCharges;
  final String? packingChargeLabel;
  final String? packingCharge;
  final String? discountLabel;
  final String? discount;
  final String? lineDiscountLabel;
  final String? totalLineDiscount;
  final String? rewardPointLabel;
  final String? rewardPointAmount;
  final String? taxLabel;
  final String? tax;
  final String? roundOffLabel;
  final String? roundOff;
  final String? totalLabel;
  final String? total;
  final String? totalInWords;
  final String? totalPaidLabel;
  final String? totalPaid;
  final String? totalDueLabel;
  final String? totalDue;
  final String? allBalLabel;
  final String? allDue;
  final String? taxSummaryLabel;
  final Map<String, dynamic>? taxes;
  final String? additionalNotes;
  final bool showBarcode;
  final bool showQrCode;
  final String? qrCodeText;
  final String? footerText;
  final List<ReceiptLine> lines;
  final List<ReceiptPayment> payments;

  ReceiptDetailsModel({
    this.logo,
    this.headerText,
    this.displayName,
    this.address,
    this.contact,
    this.website,
    this.locationCustomFields,
    this.subHeadingLine1,
    this.subHeadingLine2,
    this.subHeadingLine3,
    this.subHeadingLine4,
    this.subHeadingLine5,
    this.taxLabel1,
    this.taxInfo1,
    this.taxLabel2,
    this.taxInfo2,
    this.invoiceHeading,
    this.letterHead,
    this.invoiceNoPrefix,
    this.invoiceNo,
    this.dateLabel,
    this.invoiceDate,
    this.dueDateLabel,
    this.dueDate,
    this.salesPersonLabel,
    this.salesPerson,
    this.commissionAgentLabel,
    this.commissionAgent,
    this.customerLabel,
    this.customerInfo,
    this.clientIpLabel,
    this.clientIp,
    this.customerTaxLabel,
    this.customerTaxNumber,
    this.customerCustomFields,
    this.customerRpLabel,
    this.customerTotalRp,
    this.totalQuantityLabel,
    this.totalQuantity,
    this.totalItemsLabel,
    this.totalItems,
    this.subtotalLabel,
    this.subtotal,
    this.shippingChargesLabel,
    this.shippingCharges,
    this.packingChargeLabel,
    this.packingCharge,
    this.discountLabel,
    this.discount,
    this.lineDiscountLabel,
    this.totalLineDiscount,
    this.rewardPointLabel,
    this.rewardPointAmount,
    this.taxLabel,
    this.tax,
    this.roundOffLabel,
    this.roundOff,
    this.totalLabel,
    this.total,
    this.totalInWords,
    this.totalPaidLabel,
    this.totalPaid,
    this.totalDueLabel,
    this.totalDue,
    this.allBalLabel,
    this.allDue,
    this.taxSummaryLabel,
    this.taxes,
    this.additionalNotes,
    this.showBarcode = false,
    this.showQrCode = false,
    this.qrCodeText,
    this.footerText,
    required this.lines,
    required this.payments,
  });
}

class ReceiptLine {
  final String name;
  final String? productVariation;
  final String? variation;
  final String? subSku;
  final String? brand;
  final String? catCode;
  final String? productCustomFields;
  final String? sellLineNote;
  final String? lotNumberLabel;
  final String? lotNumber;
  final String? productExpiryLabel;
  final String? productExpiry;
  final String quantity;
  final String units;
  final String unitPriceIncTax;
  final String? totalLineDiscount;
  final String? lineDiscountPercent;
  final String lineTotal;
  final String? unitPriceBeforeDiscount;

  ReceiptLine({
    required this.name,
    this.productVariation,
    this.variation,
    this.subSku,
    this.brand,
    this.catCode,
    this.productCustomFields,
    this.sellLineNote,
    this.lotNumberLabel,
    this.lotNumber,
    this.productExpiryLabel,
    this.productExpiry,
    required this.quantity,
    required this.units,
    required this.unitPriceIncTax,
    this.totalLineDiscount,
    this.lineDiscountPercent,
    required this.lineTotal,
    this.unitPriceBeforeDiscount,
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
