import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_2/models/product_model.dart';

import '../helpers/otherHelpers.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';

class CartProvider with ChangeNotifier {
  bool proceedNext = true,
      canEditPrice = false,
      canEditDiscount = false,
      canAddServiceStaff = false,
      canAddInLineServiceStaff = false;
  int? selectedContactId,
      editItem,
      selectedTaxId = 0,
      sellingPriceGroupId = 0,
      selectedServiceStaff = 0;
  double? maxDiscountValue, discountAmount = 0.00;
  List cartItems = [];
  Map? argument = {};
  String symbol = '';
  var sellDetail, selectedDiscountType = "fixed";
  final discountController = TextEditingController();
  final searchController = TextEditingController();
  var invoiceAmount,
      taxListMap = [
        {'id': 0, 'name': 'Tax rate', 'amount': 0}
      ],
      serviceStaffListMap = [
        {'id': 0, 'name': 'Service staff'}
      ];

  void init(Map? args) {
    argument = args;
    getPermission();
    setTaxMap();
    setServiceStaffMap();
    getDefaultValues();
    getSellingPriceGroupId();
    if (argument!['sellId'] != null) editCart(argument!['sellId']);
    cartList();
  }

  Future<void> cartList() async {
    cartItems = [];
    (argument!['sellId'] != null)
        ? cartItems = await SellDatabase().getInCompleteLines(
            argument!['locationId'],
            sellId: argument!['sellId'])
        : cartItems =
            await SellDatabase().getInCompleteLines(argument!['locationId']);

    if (editItem == null) {
      proceedNext = true;
    }
    notifyListeners();
  }

  Future<void> editCart(sellId) async {
    sellDetail = await SellDatabase().getSellBySellId(sellId);
    selectedTaxId = (sellDetail[0]['tax_rate_id'] != null)
        ? sellDetail[0]['tax_rate_id']
        : 0;
    selectedServiceStaff = (sellDetail[0]['res_waiter_id'] != null)
        ? sellDetail[0]['res_waiter_id']
        : 0;
    selectedContactId = sellDetail[0]['contact_id'];
    selectedDiscountType = sellDetail[0]['discount_type'];
    discountAmount = sellDetail[0]['discount_amount'];
    discountController.text = discountAmount.toString();
    calculateSubtotal(selectedTaxId, selectedDiscountType, discountAmount);
    notifyListeners();
  }

  void getScannedProduct(String barcode) async {
    await Variations()
        .get(
            locationId: argument!['locationId'],
            barcode: barcode,
            searchTerm: '')
        .then((value) async {
      if (value.length > 0) {
        var price;
        var product;
        if (value[0]['selling_price_group'] != null) {
          jsonDecode(value[0]['selling_price_group']).forEach((element) {
            if (element['key'] == sellingPriceGroupId) {
              price = element['value'];
            }
          });
        }
        product = ProductModel().product(value[0], price);
        if (product != null && product['stock_available'] > 0) {
          Fluttertoast.showToast(msg: 'Added to cart');
          await Sell().addToCart(
              product, (argument != null) ? argument!['sellId'] : null);
          cartList();
        } else {
          Fluttertoast.showToast(msg: "Out of Stock");
        }
      } else {
        Fluttertoast.showToast(msg: "No product found");
      }
    });
    notifyListeners();
  }

  Future<List> getSearchItemList(String searchText) async {
    List products = [];
    var price;
    await Variations()
        .get(
            locationId: argument!['locationId'],
            inStock: true,
            searchTerm: searchText)
        .then((value) {
      value.forEach((element) {
        if (element['selling_price_group'] != null) {
          jsonDecode(element['selling_price_group']).forEach((element) {
            if (element['key'] == sellingPriceGroupId) {
              price = element['value'];
            }
          });
        }
        products.add(ProductModel().product(element, price));
      });
    });
    return products;
  }

  Future<void> getSellingPriceGroupId() async {
    await System().get('location').then((value) {
      value.forEach((element) {
        if (element['id'] == argument!['locationId'] &&
            element['selling_price_group_id'] != null) {
          sellingPriceGroupId =
              int.parse(element['selling_price_group_id'].toString());
        }
      });
    });
    notifyListeners();
  }

  void setTaxMap() {
    System().get('tax').then((value) {
      value.forEach((element) {
        taxListMap.add({
          'id': element['id'],
          'name': element['name'],
          'amount': double.parse(element['amount'].toString())
        });
      });
    });
    notifyListeners();
  }

  void setServiceStaffMap() {
    System().get('serviceStaff').then((value) {
      if (value != null) {
        value.forEach((element) {
          serviceStaffListMap.add({
            'id': element['id'],
            'name':
                "${element['surname'] ?? ""} ${element['first_name'] ?? ""} ${element['last_name'] ?? ""}"
          });
        });
      }
    });
    notifyListeners();
  }

  String calculateInlineUnitPrice(price, taxId, discountType, discountAmount) {
    double subTotal;
    num taxAmount = 0;
    for (var value in taxListMap) {
      if (value['id'] == taxId) {
        taxAmount = value['amount'] as num;
      }
    }
    if (discountType == 'fixed') {
      var unitPrice = price - discountAmount;
      subTotal = unitPrice + (unitPrice * taxAmount / 100);
    } else {
      var unitPrice = price - (price * discountAmount / 100);
      subTotal = unitPrice + (unitPrice * taxAmount / 100);
    }
    return subTotal.toString();
  }

  double calculateSubTotal() {
    var subTotal = 0.0;
    for (var element in cartItems) {
      subTotal += (double.parse(calculateInlineUnitPrice(
              element['unit_price'],
              element['tax_rate_id'],
              element['discount_type'],
              element['discount_amount'])) *
          element['quantity']);
    }
    return subTotal;
  }

  double calculateSubtotal(taxId, discountType, discountAmount) {
    double subTotal = calculateSubTotal();
    double finalTotal;
    num taxAmount = 0;
    for (var value in taxListMap) {
      if (value['id'] == taxId) {
        taxAmount = value['amount'] as num;
      }
    }

    if (discountType == 'fixed') {
      var total = subTotal - (discountAmount ?? 0.0);
      finalTotal = total + (total * taxAmount / 100);
    } else {
      var total = subTotal - (subTotal * (discountAmount ?? 0.0) / 100);
      finalTotal = total + (total * taxAmount / 100);
    }
    invoiceAmount = finalTotal;
    return finalTotal;
  }

  Future<void> getDefaultValues() async {
    var businessDetails = await System().get('business');
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = "${value['symbol']} ";
    });
    var userDetails = await System().get('loggedInUser');
    if (userDetails['max_sales_discount_percent'] != null) {
      maxDiscountValue =
          double.parse(userDetails['max_sales_discount_percent']);
    }
    if (sellDetail == null && businessDetails[0]['default_sales_tax'] != null) {
      selectedTaxId =
          int.parse(businessDetails[0]['default_sales_tax'].toString());
    }
    if (sellDetail == null &&
        businessDetails[0]['default_sales_discount'] != null) {
      selectedDiscountType = 'percentage';
      discountAmount =
          double.parse(businessDetails[0]['default_sales_discount']);
      discountController.text = discountAmount.toString();
      if (maxDiscountValue != null && discountAmount! > maxDiscountValue!) {
        Fluttertoast.showToast(
            msg: "Discount error message $maxDiscountValue");
        proceedNext = false;
      }
    }
    notifyListeners();
  }

  Future<void> getPermission() async {
    canEditPrice =
        await Helper().getPermission("edit_product_price_from_pos_screen");
    canEditDiscount =
        await Helper().getPermission("edit_product_discount_from_pos_screen");
    await Helper().getFormattedBusinessDetails().then((value) {
      List enabledModules = value['enabledModules'];
      Map<String, dynamic> posSettings = value['posSettings'];
      if (posSettings.isNotEmpty &&
          posSettings.containsKey("inline_service_staff")) {
        if (posSettings["inline_service_staff"].toString() == "1") {
          canAddInLineServiceStaff = true;
        }
      }
      if (enabledModules.isNotEmpty &&
          enabledModules.contains('service_staff')) {
        canAddServiceStaff = true;
      }
    });
    notifyListeners();
  }

  void updateDiscount(String value) {
    discountAmount = Helper().validateInput(value);
    if (maxDiscountValue != null && discountAmount! > maxDiscountValue!) {
      Fluttertoast.showToast(msg: "Discount error message $maxDiscountValue");
      proceedNext = false;
    } else {
      proceedNext = true;
    }
    notifyListeners();
  }

  void setDiscountType(String type) {
    selectedDiscountType = type;
    calculateSubtotal(selectedTaxId, selectedDiscountType, discountAmount);
    notifyListeners();
  }

  void setTax(int taxId) {
    selectedTaxId = taxId;
    notifyListeners();
  }

  void setServiceStaff(int staffId) {
    selectedServiceStaff = staffId;
    notifyListeners();
  }

  void setEditItem(int? index) {
    editItem = index;
    notifyListeners();
  }

  void deleteCartItem(int variationId, int productId, {int? sellId}) {
    (sellId == null)
        ? SellDatabase().delete(variationId, productId)
        : SellDatabase().delete(variationId, productId, sellId: sellId);
    editItem = null;
    cartList();
    notifyListeners();
  }

  void updateQuantity(int id, double newQuantity, double stockAvailable) {
    if (newQuantity > 0) {
      if (!proceedNext) proceedNext = true;
      if (stockAvailable >= newQuantity) {
        SellDatabase().update(id, {'quantity': newQuantity});
        cartList();
      } else {
        Fluttertoast.showToast(msg: "$stockAvailable stock available");
      }
    } else {
      proceedNext = false;
      Fluttertoast.showToast(msg: 'Please enter a valid quantity');
    }
    notifyListeners();
  }

  void incrementQuantity(int id, double currentQuantity, double stockAvailable) {
    if (stockAvailable > currentQuantity) {
      SellDatabase().update(id, {'quantity': currentQuantity + 1});
      cartList();
    } else {
      Fluttertoast.showToast(msg: "$stockAvailable stock available");
    }
    notifyListeners();
  }

  void decrementQuantity(int id, double currentQuantity) {
    if (currentQuantity > 1) {
      SellDatabase().update(id, {'quantity': currentQuantity - 1});
      cartList();
    }
    notifyListeners();
  }
}
