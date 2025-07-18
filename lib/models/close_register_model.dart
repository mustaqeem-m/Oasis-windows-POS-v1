class CloseRegisterModel {
  final String registerPeriod;
  final List<PaymentDetail> paymentDetails;
  final Totals totals;
  final List<SoldProduct> soldProducts;
  final Discounts discounts;
  final List<BrandSale> soldByBrand;
  final List<ServiceType> serviceTypes;
  final CashSummary cashSummary;
  final ClosingNote closingNote;

  CloseRegisterModel({
    required this.registerPeriod,
    required this.paymentDetails,
    required this.totals,
    required this.soldProducts,
    required this.discounts,
    required this.soldByBrand,
    required this.serviceTypes,
    required this.cashSummary,
    required this.closingNote,
  });

  factory CloseRegisterModel.fromJson(Map<String, dynamic> json) {
    return CloseRegisterModel(
      registerPeriod: json['registerPeriod'],
      paymentDetails: (json['paymentDetails'] as List)
          .map((i) => PaymentDetail.fromJson(i))
          .toList(),
      totals: Totals.fromJson(json['totals']),
      soldProducts: (json['soldProducts'] as List)
          .map((i) => SoldProduct.fromJson(i))
          .toList(),
      discounts: Discounts.fromJson(json['discounts']),
      soldByBrand: (json['soldByBrand'] as List)
          .map((i) => BrandSale.fromJson(i))
          .toList(),
      serviceTypes: (json['serviceTypes'] as List)
          .map((i) => ServiceType.fromJson(i))
          .toList(),
      cashSummary: CashSummary.fromJson(json['cashSummary']),
      closingNote: ClosingNote.fromJson(json['closingNote']),
    );
  }
}

class PaymentDetail {
  final String method;
  final String sell;
  final String expense;

  PaymentDetail({required this.method, required this.sell, required this.expense});

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      method: json['method'],
      sell: json['sell'],
      expense: json['expense'],
    );
  }
}

class Totals {
  final String totalSales;
  final String refund;
  final String payment;
  final String creditSales;
  final String finalSales;
  final String expenses;
  final String cashCalculation;

  Totals({
    required this.totalSales,
    required this.refund,
    required this.payment,
    required this.creditSales,
    required this.finalSales,
    required this.expenses,
    required this.cashCalculation,
  });

  factory Totals.fromJson(Map<String, dynamic> json) {
    return Totals(
      totalSales: json['totalSales'],
      refund: json['refund'],
      payment: json['payment'],
      creditSales: json['creditSales'],
      finalSales: json['finalSales'],
      expenses: json['expenses'],
      cashCalculation: json['cashCalculation'],
    );
  }
}

class SoldProduct {
  final String sku;
  final String product;
  final String quantity;
  final String amount;

  SoldProduct({
    required this.sku,
    required this.product,
    required this.quantity,
    required this.amount,
  });

  factory SoldProduct.fromJson(Map<String, dynamic> json) {
    return SoldProduct(
      sku: json['sku'],
      product: json['product'],
      quantity: json['quantity'],
      amount: json['amount'],
    );
  }
}

class Discounts {
  final String discount;
  final String shipping;
  final String grandTotal;

  Discounts({
    required this.discount,
    required this.shipping,
    required this.grandTotal,
  });

  factory Discounts.fromJson(Map<String, dynamic> json) {
    return Discounts(
      discount: json['discount'],
      shipping: json['shipping'],
      grandTotal: json['grandTotal'],
    );
  }
}

class BrandSale {
  final String brand;
  final String quantity;
  final String amount;

  BrandSale({required this.brand, required this.quantity, required this.amount});

  factory BrandSale.fromJson(Map<String, dynamic> json) {
    return BrandSale(
      brand: json['brand'],
      quantity: json['quantity'],
      amount: json['amount'],
    );
  }
}

class ServiceType {
  final String type;
  final String amount;

  ServiceType({required this.type, required this.amount});

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      type: json['type'],
      amount: json['amount'],
    );
  }
}

class CashSummary {
  final String totalCash;
  final String cardSlips;
  final String cheques;
  final String denominationNote;

  CashSummary({
    required this.totalCash,
    required this.cardSlips,
    required this.cheques,
    required this.denominationNote,
  });

  factory CashSummary.fromJson(Map<String, dynamic> json) {
    return CashSummary(
      totalCash: json['totalCash'],
      cardSlips: json['cardSlips'],
      cheques: json['cheques'],
      denominationNote: json['denominationNote'],
    );
  }
}

class ClosingNote {
  final String user;
  final String email;
  final String location;

  ClosingNote({required this.user, required this.email, required this.location});

  factory ClosingNote.fromJson(Map<String, dynamic> json) {
    return ClosingNote(
      user: json['user'],
      email: json['email'],
      location: json['location'],
    );
  }
}
