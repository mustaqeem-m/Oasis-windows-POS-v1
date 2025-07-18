import 'package:pos_2/models/register_entry.dart';

class RegisterDetails {
  final List<RegisterEntry> registerEntries;
  final List<SoldProduct> soldProducts;
  final List<BrandSales> brandSales;
  final List<ServiceTypeSummary> serviceTypes;
  final DateTime startDate;
  final DateTime endDate;
  final double totalRefund;
  final double totalPayment;
  final double creditSales;
  final double finalSales;
  final double computedTotal;
  final double discount;
  final double shipping;
  final String user;
  final String email;
  final String location;

  RegisterDetails({
    required this.registerEntries,
    required this.soldProducts,
    required this.brandSales,
    required this.serviceTypes,
    required this.startDate,
    required this.endDate,
    required this.totalRefund,
    required this.totalPayment,
    required this.creditSales,
    required this.finalSales,
    required this.computedTotal,
    required this.discount,
    required this.shipping,
    required this.user,
    required this.email,
    required this.location,
  });
}

class SoldProduct {
  final int index;
  final String sku;
  final String product;
  final double quantity;
  final double total;

  SoldProduct({
    required this.index,
    required this.sku,
    required this.product,
    required this.quantity,
    required this.total,
  });
}

class BrandSales {
  final int index;
  final String brand;
  final double quantity;
  final double total;

  BrandSales({
    required this.index,
    required this.brand,
    required this.quantity,
    required this.total,
  });
}

class ServiceTypeSummary {
  final int index;
  final String type;
  final double amount;

  ServiceTypeSummary({
    required this.index,
    required this.type,
    required this.amount,
  });
}