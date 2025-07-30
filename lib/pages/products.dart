import 'package:pos_2/apis/commission_agent.dart';
import 'package:pos_2/apis/printer.dart';
import 'package:pos_2/apis/service_staff.dart';
import 'package:pos_2/apis/table.dart';
import 'package:pos_2/apis/types_of_service.dart';
import 'package:pos_2/components/discount_dialog.dart';
import 'package:pos_2/providers/cart_provider.dart';
import 'package:pos_2/components/sell_return_popup.dart';
import 'package:pos_2/components/recent_transactions_dialog.dart';
import 'package:pos_2/components/service_staff_popup.dart';
import 'package:pos_2/components/add_expense_dialog.dart';
import 'package:pos_2/models/expense_database.dart';
import 'package:pos_2/components/open_register_dialog.dart';
import 'package:pos_2/models/register_database.dart';
import 'package:pos_2/components/close_register_dialog.dart';
import 'package:pos_2/components/shipping_modal.dart';
import 'package:pos_2/components/calculator_popup.dart';
import 'package:pos_2/components/print_receipt_dialog.dart';
import 'package:pos_2/components/register_details/register_details_dialog.dart';
import 'package:pos_2/models/contact_model.dart';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_2/helpers/otherHelpers.dart';
import 'package:pos_2/helpers/toast_helper.dart';
import 'package:pos_2/models/register_entry.dart';
import 'package:pos_2/providers/home_provider.dart';
import 'package:provider/provider.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/generators.dart';
import '../locale/MyLocalizations.dart';
import '../models/product_model.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';
import 'package:pos_2/models/paymentDatabase.dart';
import 'package:pos_2/apis/user.dart';
import 'package:pos_2/models/close_register_model.dart';
import 'package:pos_2/models/register_details_models.dart' as register_details;
import 'package:pos_2/components/home/suspended_sales_modal.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  ProductsState createState() => ProductsState();
}

class ProductsState extends State<Products> with AutomaticKeepAliveClientMixin {
  double _shippingCharges = 0.0;
  double _roundOffAmount = 0.0;
  final CartProvider _cartProvider = CartProvider();
  List products = [];
  List<Map<String, dynamic>> cartLines = [];
  List<Map<String, dynamic>> _customers = [];
  List<dynamic> _commissionAgents = [];
  List<dynamic> _typesOfService = [];
  List<dynamic> _tables = [];
  List<dynamic> _serviceStaff = [];
  List<dynamic> _printers = [];
  int? _selectedCustomerId;
  int? _selectedCommissionAgentId;
  int? _selectedTypesOfServiceId;
  int? _selectedTableId;
  int? _selectedServiceStaffId;
  int? _selectedPrinterId;
  static int themeType = 1;
  late ThemeData themeData;
  bool _isLoading = true;
  bool changeLocation = false,
      canChangeLocation = true,
      canMakeSell = false,
      inStock = true,
      canAddSell = true,
      canViewProducts = true,
      usePriceGroup = true;

  int selectedLocationId = 0,
      categoryId = 0,
      subCategoryId = 0,
      brandId = 0,
      cartCount = 0,
      sellingPriceGroupId = 0;
  int? byAlphabets, byPrice;

  final List<DropdownMenuItem<int>> _categoryMenuItems = [];
  final List<DropdownMenuItem<int>> _subCategoryMenuItems = [];
  final List<DropdownMenuItem<int>> _brandsMenuItems = [];
  List<DropdownMenuItem<bool>> _priceGroupMenuItems = [];
  Map? argument;
  List<Map<String, dynamic>> locationListMap = [
    {'id': 0, 'name': 'set location', 'selling_price_group_id': 0}
  ];

  String symbol = '';
  final searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _productSearchFocusNode = FocusNode();
  final _productSearchController = TextEditingController();
  List<dynamic> _suggestedProducts = [];
  DateTime _selectedDate = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    themeData = AppTheme.getThemeFromThemeMode(themeType);
    _initializePage().then((_) {
      _loadSavedLocation().then((_) {
        if (selectedLocationId != 0) {
          setInitDetails(selectedLocationId);
        }
      });
    });
    _cartProvider.addListener(_onCartProviderChanged);
    _productSearchFocusNode.requestFocus();
  }

  Future<void> _loadSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLocationId = prefs.getInt('selectedLocationId') ?? 0;
    });
  }

  void _onCartProviderChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showSuspendedSalesModal(BuildContext context) async {
    final suspendedSales = await Sell().getSells(status: 'suspended');
    showDialog(
      context: context,
      builder: (context) {
        return SuspendedSalesModal(suspendedSales: suspendedSales);
      },
    );
  }

  Future<void> _initializePage() async {
    await System().refresh();
    _cartProvider.init(null);

    await Future.wait<dynamic>([
      setLocationMap(),
      categoryList(),
      subCategoryList(categoryId),
      brandList(),
      _getCustomers(),
      _getCommissionAgents(),
      _getTypesOfService(),
      _getTables(),
      _getServiceStaff(),
      _getPrinters(),
      _getCartLines(),
    ]);

    await Helper().syncCallLogs();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCustomers() async {
    final customers = await Contact().get();
    if (mounted) {
      setState(() {
        _customers = customers;
        var homeProvider = Provider.of<HomeProvider>(context, listen: false);
        if (homeProvider.selectedCustomer['id'] != null) {
          _selectedCustomerId = homeProvider.selectedCustomer['id'];
        } else if (_customers.isNotEmpty) {
          var walkIn = _customers.firstWhere(
              (c) => c['name']?.toLowerCase() == 'walk-in customer',
              orElse: () => _customers.first);
          _selectedCustomerId = walkIn['id'];
          homeProvider.updateSelectedCustomer(walkIn);
        }
      });
    }
  }

  Future<void> _getCommissionAgents() async {
    final agents = await CommissionAgentApi().get();
    if (mounted) {
      setState(() {
        _commissionAgents = agents;
      });
    }
  }

  Future<void> _getTypesOfService() async {
    final services = await TypesOfServiceApi().get();
    if (mounted) {
      setState(() {
        _typesOfService = services;
      });
    }
  }

  Future<void> _getTables() async {
    final tables = await TableApi().get();
    if (mounted) {
      setState(() {
        _tables = tables;
      });
    }
  }

  Future<void> _getServiceStaff() async {
    final staff = await ServiceStaffApi().get();
    if (mounted) {
      setState(() {
        _serviceStaff = staff;
      });
    }
  }

  Future<void> _getPrinters() async {
    final printers = await PrinterApi().get();
    if (mounted) {
      setState(() {
        _printers = printers;
        if (_printers.isNotEmpty) {
          _selectedPrinterId = _printers.first['id'];
        }
      });
      // ToastHelper.show(
      //     context, "Printers loaded: ${_printers.length}. Selected ID: $_selectedPrinterId");
    }
  }

  Future<void> _getCartLines() async {
    final lines = await Sell().getCartLines();
    if (mounted) {
      setState(() {
        cartLines = lines;
      });
    }
  }

  bool _isInitialized = false;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final newArguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (argument != newArguments) {
        argument = newArguments;
        if (argument != null) {
          if (mounted) {
            setState(() {
              selectedLocationId = argument!['locationId'];
              canChangeLocation = false;
            });
          }
        } else {
          canChangeLocation = true;
        }
        if (!mounted) return;
        await setInitDetails(selectedLocationId);
      }
      _isInitialized = true;
    }
  }

  //Set location & product
  Future<void> setInitDetails(int selectedLocationId) async {
    //check subscription
    final activeSubscriptionDetails = await System().get('active-subscription');
    if (activeSubscriptionDetails.isNotEmpty) {
      if (mounted) {
        setState(() {
          canMakeSell = true;
        });
      }
    } else {
      if (!mounted) return;
      ToastHelper.show(context,
          AppLocalizations.of(context).translate('no_subscription_found'));
    }
    if (!mounted) return;
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = '${value['symbol']} ';
    });
    if (!mounted) return;
    setDefaultLocation(selectedLocationId);
    await productList(resetOffset: true);
  }

  //set selling Price Group Id
  void findSellingPriceGroupId(int locId) {
    if (usePriceGroup) {
      for (var element in locationListMap) {
        if (element['id'] == selectedLocationId &&
            element['selling_price_group_id'] != null) {
          sellingPriceGroupId =
              int.parse(element['selling_price_group_id'].toString());
        } else if (element['id'] == selectedLocationId &&
            element['selling_price_group_id'] == null) {
          sellingPriceGroupId = 0;
        }
      }
    } else {
      sellingPriceGroupId = 0;
    }
  }

  //set product list
  Future<void> productList({bool resetOffset = false}) async {
    if (resetOffset && mounted) {
      setState(() {
        products = <dynamic>[];
      });
    }

    String? lastSync = await System().getProductLastSync();
    final date2 = DateTime.now();
    if (lastSync == null ||
        (date2.difference(DateTime.parse(lastSync)).inMinutes > 10)) {
      if (await Helper().checkConnectivity()) {
        await Variations().refresh();
        await System().insertProductLastSyncDateTimeNow();
      }
    }

    findSellingPriceGroupId(selectedLocationId);
    List<dynamic> newProducts = [];
    var variations = await Variations().get(
        brandId: brandId,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        inStock: inStock,
        locationId: selectedLocationId,
        searchTerm: searchController.text,
        byAlphabets: byAlphabets,
        byPrice: byPrice);

    for (var product in variations) {
      dynamic price;
      if (product['selling_price_group'] != null) {
        jsonDecode(product['selling_price_group']).forEach((element) {
          if (element['key'] == sellingPriceGroupId) {
            price = double.parse(element['value'].toString());
          }
        });
      }
      newProducts.add(ProductModel().product(product, price));
    }

    if (mounted) {
      setState(() {
        if (resetOffset) {
          products = newProducts;
        } else {
          products.addAll(newProducts);
        }
      });
    }
  }

  Future<void> categoryList() async {
    List<dynamic> categories = await System().getCategories();
    if (!mounted) return;
    _categoryMenuItems.clear();
    _categoryMenuItems.add(
      DropdownMenuItem(
        value: 0,
        child: Text(AppLocalizations.of(context).translate('select_category')),
      ),
    );

    for (var category in categories) {
      _categoryMenuItems.add(
        DropdownMenuItem(
          value: category['id'],
          child: Text(category['name']),
        ),
      );
    }
  }

  Future<void> subCategoryList(int parentId) async {
    List<dynamic> subCategories = await System().getSubCategories(parentId);
    if (!mounted) return;
    _subCategoryMenuItems.clear();
    _subCategoryMenuItems.add(
      DropdownMenuItem(
        value: 0,
        child:
            Text(AppLocalizations.of(context).translate('select_sub_category')),
      ),
    );
    for (var element in subCategories) {
      _subCategoryMenuItems.add(
        DropdownMenuItem<int>(
          value: jsonDecode(element['value'])['id'],
          child: Text(jsonDecode(element['value'])['name']),
        ),
      );
    }
  }

  Future<void> brandList() async {
    List<dynamic> brands = await System().getBrands();
    if (!mounted) return;
    _brandsMenuItems.clear();
    _brandsMenuItems.add(
      DropdownMenuItem(
        value: 0,
        child: Text(AppLocalizations.of(context).translate('select_brand')),
      ),
    );

    for (var brand in brands) {
      _brandsMenuItems.add(
        DropdownMenuItem(
          value: brand['id'],
          child: Text(brand['name']),
        ),
      );
    }
  }

  Future<void> priceGroupList() async {
    if (mounted) {
      setState(() {
        _priceGroupMenuItems = [];
        _priceGroupMenuItems.add(
          DropdownMenuItem(
            value: false,
            child: Text(AppLocalizations.of(context)
                .translate('no_price_group_selected')),
          ),
        );

        bool trueAdded = false;
        for (var element in locationListMap) {
          if (element['id'] == selectedLocationId &&
              element['selling_price_group_id'] != null) {
            if (!trueAdded) {
              _priceGroupMenuItems.add(
                DropdownMenuItem<bool>(
                  value: true,
                  child: Text(AppLocalizations.of(context)
                      .translate('default_price_group')),
                ),
              );
              trueAdded = true;
            }
          }
        }

        if (!trueAdded) {
          usePriceGroup = false;
        }
      });
    }
  }

  Future<String> getCartItemCount({dynamic isCompleted, dynamic sellId}) async {
    final String counts =
        await Sell().cartItemCount(isCompleted: isCompleted, sellId: sellId);
    if (mounted) {
      setState(() {
        cartCount = int.parse(counts);
      });
    }
    return counts;
  }

  double findAspectRatio(double width) {
    //Logic for aspect ratio of grid view
    return (width / 2 - 16.0) / ((width / 2 - 16.0) + 60);
  }

  void _showCalculatorPopup(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          enabled: false,
          child: CalculatorPopup(),
        ),
      ],
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Future<void> _showShippingDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return ShippingModal(
          shippingCharges: _shippingCharges.toString(),
        );
      },
    );

    if (result != null && result['shippingCharges'] != null) {
      setState(() {
        _shippingCharges =
            double.tryParse(result['shippingCharges'].toString()) ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate totals here
    double _subtotal = cartLines.fold(0.0, (sum, line) {
      double price = double.parse(line['unit_price']?.toString() ?? '0');
      double quantity = line['quantity'] ?? 0;
      return sum + (price * quantity);
    });

    double discountValue = 0;
    if (_cartProvider.selectedDiscountType == 'fixed') {
      discountValue = _cartProvider.discountAmount ?? 0.0;
    } else if (_cartProvider.selectedDiscountType == 'percentage') {
      discountValue = (_subtotal * (_cartProvider.discountAmount ?? 0.0)) / 100;
    }

    double taxAmount = _cartProvider.orderTaxAmount ?? 0.0;
    double unroundedTotal =
        _subtotal - discountValue + taxAmount + _shippingCharges;
    double totalPayable = unroundedTotal.floor().toDouble();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _roundOffAmount = unroundedTotal - totalPayable;
        });
      }
    });

    return ChangeNotifierProvider.value(
      value: _cartProvider,
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF7F8FC),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTopBar(),
                  _buildProductSearchField(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildLeftPanel(),
                    ),
                  ),
                ],
              ),
        endDrawer: SizedBox(
          width: screenWidth * 0.4,
          child: Drawer(
            child: _buildRightPanel(),
          ),
        ),
        bottomNavigationBar: _buildStickyBottomBar(totalPayable),
      ),
    );
  }

  Future<void> _showRegisterDetails() async {
    await showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (context) => OpenRegisterDialog(
        onConfirm: (openingBalance) async {
          await RegisterDatabase().insertOpeningBalance(openingBalance);
          if (!mounted) return;
          final registerDetails = await _getRegisterDetailsData();
          showRegisterDetailsDialog(
            _scaffoldKey.currentContext!,
            registerDetails.registerEntries,
            registerDetails.soldProducts,
            registerDetails.brandSales,
            registerDetails.serviceTypes,
            registerDetails.startDate,
            registerDetails.endDate,
            registerDetails.totalRefund,
            registerDetails.totalPayment,
            registerDetails.creditSales,
            registerDetails.finalSales,
            registerDetails.computedTotal,
            registerDetails.discount,
            registerDetails.shipping,
            registerDetails.user,
            registerDetails.email,
            registerDetails.location,
          );
        },
      ),
    );
  }

  Future<void> _showCloseRegisterDialog() async {
    final data = await _getCloseRegisterData();
    if (!mounted) return;
    showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (BuildContext context) {
        return CloseRegisterDialog(data: data);
      },
    );
  }

  Future<CloseRegisterModel> _getCloseRegisterData() async {
    final registerDetails = await _getRegisterDetailsData();
    final expenses = await ExpenseDatabase().getExpenses();
    final totalExpenses =
        expenses.fold<double>(0.0, (sum, item) => sum + item['amount']);

    return CloseRegisterModel(
      registerPeriod:
          '${DateFormat('dd MMM, yyyy hh:mm a').format(registerDetails.startDate)} - ${DateFormat('dd MMM, yyyy hh:mm a').format(registerDetails.endDate)}',
      paymentDetails: registerDetails.registerEntries
          .map((e) => PaymentDetail(
                method: e.method,
                sell: '₹ ${e.sell.toStringAsFixed(2)}',
                expense: '₹ ${e.expense.toStringAsFixed(2)}',
              ))
          .toList(),
      totals: Totals(
        totalSales: '₹ ${registerDetails.finalSales.toStringAsFixed(2)}',
        refund: '₹ ${registerDetails.totalRefund.toStringAsFixed(2)}',
        payment: '₹ ${registerDetails.totalPayment.toStringAsFixed(2)}',
        creditSales: '₹ ${registerDetails.creditSales.toStringAsFixed(2)}',
        finalSales: '₹ ${registerDetails.finalSales.toStringAsFixed(2)}',
        expenses:
            '₹ ${totalExpenses.toStringAsFixed(2)}', // Replace with actual expense data if available
        cashCalculation:
            '₹ ${await RegisterDatabase().getOpeningBalance()} (opening) + ₹ ${registerDetails.finalSales.toStringAsFixed(2)} (Sale) - ₹ ${registerDetails.totalRefund.toStringAsFixed(2)} (Refund) - ₹ ${totalExpenses.toStringAsFixed(2)} (Expense) = ₹ ${(await RegisterDatabase().getOpeningBalance() + registerDetails.finalSales - registerDetails.totalRefund - totalExpenses).toStringAsFixed(2)}',
      ),
      soldProducts: registerDetails.soldProducts
          .map((p) => SoldProduct(
                sku: p.sku,
                product: p.product,
                quantity: p.quantity.toString(),
                amount: '₹ ${p.total.toStringAsFixed(2)}',
              ))
          .toList(),
      discounts: Discounts(
        discount: '₹ ${registerDetails.discount.toStringAsFixed(2)}',
        shipping: '₹ ${registerDetails.shipping.toStringAsFixed(2)}',
        grandTotal:
            '₹ ${(registerDetails.finalSales + registerDetails.shipping).toStringAsFixed(2)}',
      ),
      soldByBrand: registerDetails.brandSales
          .map((b) => BrandSale(
                brand: b.brand,
                quantity: b.quantity.toString(),
                amount: '₹ ${b.total.toStringAsFixed(2)}',
              ))
          .toList(),
      serviceTypes: [], // Replace with actual service type data if available
      cashSummary: CashSummary(
        totalCash: '₹ ${registerDetails.totalPayment.toStringAsFixed(2)}',
        cardSlips: '1', // Replace with actual card slips data if available
        cheques: '0', // Replace with actual cheques data if available
        denominationNote:
            'Add denominations in Settings -> Business Settings -> POS -> Cash Denominations',
      ),
      closingNote: ClosingNote(
        user: registerDetails.user,
        email: registerDetails.email,
        location: registerDetails.location,
      ),
    );
  }

  Future<register_details.RegisterDetails> _getRegisterDetailsData() async {
    // Fetch all completed sales
    final sales = await SellDatabase().getSells(all: true);
    final List<RegisterEntry> registerEntries = [];
    final List<register_details.SoldProduct> soldProducts = [];
    final List<register_details.BrandSales> brandSales = [];
    double totalRefund = 0;
    double creditSales = 0;
    double discount = 0;
    double shipping = 0;
    double totalSell = 0;

    for (var sale in sales) {
      final payments = await PaymentDatabase().get(sale['id']);
      double saleTotal = 0;
      for (var payment in payments) {
        saleTotal += payment['amount'];
        if (payment['method'] == 'cash') {
          registerEntries.add(RegisterEntry(
              method: 'Cash Payment', sell: payment['amount'], expense: 0));
        } else if (payment['method'] == 'card') {
          registerEntries.add(RegisterEntry(
              method: 'Card Payment', sell: payment['amount'], expense: 0));
        } else if (payment['method'] == 'upi') {
          registerEntries.add(RegisterEntry(
              method: 'UPI Payment', sell: payment['amount'], expense: 0));
        }
      }

      totalSell += saleTotal;
      discount += sale['discount_amount'] ?? 0;
      shipping += sale['shipping_charges'] ?? 0;

      if (sale['status'] == 'credit_sale') {
        creditSales += saleTotal;
      }

      final sellLines = await SellDatabase().getSellLines(sale['id']);
      for (var line in sellLines) {
        final product =
            await Variations().getVariationById(line['variation_id']);
        soldProducts.add(register_details.SoldProduct(
          index: soldProducts.length + 1,
          sku: product['sub_sku'],
          product: product['display_name'],
          quantity: line['quantity'],
          total: line['unit_price'] * line['quantity'],
        ));

        final brand = await System().getBrandById(product['brand_id']);
        final existingBrandIndex =
            brandSales.indexWhere((b) => b.brand == brand['name']);
        if (existingBrandIndex != -1) {
          final existingBrand = brandSales[existingBrandIndex];
          brandSales[existingBrandIndex] = register_details.BrandSales(
            index: existingBrand.index,
            brand: existingBrand.brand,
            quantity: existingBrand.quantity + line['quantity'],
            total:
                existingBrand.total + (line['unit_price'] * line['quantity']),
          );
        } else {
          brandSales.add(register_details.BrandSales(
            index: brandSales.length + 1,
            brand: brand['name'] ?? 'Unknown Brand',
            quantity: line['quantity'],
            total: line['unit_price'] * line['quantity'],
          ));
        }
      }
    }

    final totalPayment = totalSell - totalRefund;
    final finalSales = totalPayment - creditSales;
    final openingBalance = await RegisterDatabase().getOpeningBalance();
    final computedTotal = openingBalance + totalSell - totalRefund;

    final locationData = locationListMap.firstWhere(
        (loc) => loc['id'] == selectedLocationId,
        orElse: () => {'name': 'Unknown'});

    final token = await System().getToken();
    final userDetails = await User().get(token);

    return register_details.RegisterDetails(
      registerEntries: registerEntries,
      soldProducts: soldProducts,
      brandSales: brandSales,
      serviceTypes: [], // Fetch this data if available
      startDate: DateTime.now().subtract(const Duration(hours: 8)),
      endDate: DateTime.now(),
      totalRefund: totalRefund,
      totalPayment: totalPayment,
      creditSales: creditSales,
      finalSales: finalSales,
      computedTotal: computedTotal,
      discount: discount,
      shipping: shipping,
      user: userDetails['first_name'] + ' ' + userDetails['last_name'],
      email: userDetails['email'],
      location: locationData['name'],
    );
  }

  Future<void> _onSearchChanged(String searchTerm) async {
    if (searchTerm.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestedProducts = [];
        });
      }
      return;
    }

    findSellingPriceGroupId(selectedLocationId);
    final variations = await Variations().get(
      searchTerm: searchTerm,
      locationId: selectedLocationId,
    );

    List<dynamic> newProducts = [];
    for (var product in variations) {
      dynamic price;
      if (product['selling_price_group'] != null) {
        jsonDecode(product['selling_price_group']).forEach((element) {
          if (element['key'] == sellingPriceGroupId) {
            price = double.parse(element['value'].toString());
          }
        });
      }
      newProducts.add(ProductModel().product(product, price));
    }

    final exactMatch = newProducts.firstWhere(
      (p) =>
          p['sub_sku']?.toLowerCase() == searchTerm.toLowerCase() ||
          p['display_name']?.toLowerCase() == searchTerm.toLowerCase(),
      orElse: () => null,
    );

    if (exactMatch != null && newProducts.length == 1) {
      await onTapProduct(exactMatch);
      _productSearchController.clear();
      if (mounted) {
        setState(() {
          _suggestedProducts = [];
        });
        _productSearchFocusNode.requestFocus();
      }
    } else {
      if (mounted) {
        setState(() {
          _suggestedProducts = newProducts;
        });
      }
    }
  }

  Widget _buildProductSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _productSearchController,
            focusNode: _productSearchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by Product Name or SKU...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _productSearchController.clear();
                  setState(() {
                    _suggestedProducts = [];
                  });
                },
              ),
            ),
          ),
          if (_suggestedProducts.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 250,
              ),
              child: Card(
                elevation: 4,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestedProducts.length,
                  itemBuilder: (context, index) {
                    final product = _suggestedProducts[index];
                    return ListTile(
                      title: Text(product['display_name']),
                      subtitle: Text(
                          'SKU: ${product['sub_sku']} - Stock: ${product['stock_available'] ?? 'N/A'}'),
                      onTap: () {
                        onTapProduct(product);
                        _productSearchController.clear();
                        setState(() {
                          _suggestedProducts = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Location Dropdown
            _buildLocationDropdown(),
            const SizedBox(width: 16),

            // Datetime Picker
            _buildDateTimePicker(),
            const SizedBox(width: 16),

            // Action Buttons
            Tooltip(
              message: 'Show Products',
              child: _buildActionIconButton(Icons.grid_view, () {
                _scaffoldKey.currentState!.openEndDrawer();
              }),
            ),
            Tooltip(
              message: 'Back',
              child: _buildActionIconButton(Icons.arrow_back, () {}),
            ),
            Tooltip(
              message: 'Close register',
              child: _buildActionIconButton(
                  Icons.close, _showCloseRegisterDialog,
                  color: Colors.red),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: const ServiceStaffPopup(),
            ),
            Tooltip(
              message: 'Open Cash Register',
              child: _buildActionIconButton(
                  Icons.business_center_outlined, _showRegisterDetails),
            ),
            Tooltip(
              message: 'Calculator Popup',
              child: _buildActionIconButton(Icons.calculate_outlined, () {
                _showCalculatorPopup(context);
              }),
            ),
            const SellReturnPopup(),

            Tooltip(
              message: 'View suspended sales',
              child: _buildActionIconButton(Icons.pause, () {
                _showSuspendedSalesModal(context);
              }),
            ),
            Tooltip(
              message: 'Customer Display Screen',
              child: _buildActionIconButton(Icons.display_settings_rounded, () {
                Navigator.pushNamed(context, '/customer-display');
              }),
            ),
            const SizedBox(width: 16),

            // Far Right Buttons
            Visibility(
              visible: Provider.of<HomeProvider>(context).showRepairButton,
              child: _buildTextIconButton(
                  'Repair', Icons.build_outlined, Colors.lightBlue),
            ),
            const SizedBox(width: 30),
            _buildTextIconButton(
                'Add Expense', Icons.add_card_outlined, Colors.transparent,
                borderColor: Colors.black, onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddExpenseDialog(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton(IconData icon, VoidCallback onPressed,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: color ?? Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: color ?? Colors.black, size: 20),
        ),
      ),
    );
  }

  Widget _buildTextIconButton(
      String label, IconData icon, Color backgroundColor,
      {Color? borderColor, VoidCallback? onPressed}) {
    return TextButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: borderColor ?? Colors.transparent),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return SizedBox(
      width: 200,
      height: 39,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            dropdownColor: Colors.white,
            value: selectedLocationId,
            items: locationListMap.map<DropdownMenuItem<int>>((Map value) {
              return DropdownMenuItem<int>(
                value: value['id'],
                child: Text(
                  value['name'],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
            onChanged: (int? newValue) async {
              if (canChangeLocation) {
                if (selectedLocationId == newValue) {
                  changeLocation = false;
                } else if (selectedLocationId != 0) {
                  await _showCartResetDialogForLocation();
                  await priceGroupList();
                } else {
                  changeLocation = true;
                  await priceGroupList();
                }
                if (mounted) {
                  setState(() {
                    if (changeLocation) {
                      Sell().resetCart();
                      selectedLocationId = newValue!;
                      brandId = 0;
                      categoryId = 0;
                      searchController.clear();
                      inStock = true;
                      cartCount = 0;
                      productList(resetOffset: true);
                    }
                  });
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setInt('selectedLocationId', selectedLocationId);
                }
              } else {
                if (!mounted) return;
                ToastHelper.show(
                    context,
                    AppLocalizations.of(context)
                        .translate('cannot_change_location'));
              }
            },
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd MMM, yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        _buildCustomerAndInputSection(),
        const SizedBox(height: 16),
        Expanded(child: _buildCartItemsList()),
        const SizedBox(height: 16),
        _buildCartSummary(),
      ],
    );
  }

  Widget _buildCustomerAndInputSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCustomerDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Visibility(
                  visible: Provider.of<HomeProvider>(context)
                      .dropdownVisibilities['showPriceTypeDropdown']!,
                  child: _buildDropdownField(
                    icon: MdiIcons.tagOutline,
                    label: 'Price Type',
                    value: 'Default Selling Price',
                    onTap: () {
                      // TODO: Implement price type selection
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Visibility(
                  visible: Provider.of<HomeProvider>(context)
                      .dropdownVisibilities['showPrinter']!,
                  child: _buildPrinterDropdown(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Visibility(
                  visible: Provider.of<HomeProvider>(context)
                      .dropdownVisibilities['showCommissionAgent']!,
                  child: _buildCommissionAgentDropdown(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Visibility(
                  visible: Provider.of<HomeProvider>(context)
                      .dropdownVisibilities['showTypesOfService']!,
                  child: _buildTypesOfServiceDropdown(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  icon: MdiIcons.calendarBlankOutline,
                  label: 'Date',
                  value: DateFormat('dd MMM, yyyy').format(_selectedDate),
                  onTap: _selectDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Visibility(
                  visible: Provider.of<HomeProvider>(context)
                      .dropdownVisibilities['showTable']!,
                  child: _buildTableDropdown(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Visibility(
                  visible: Provider.of<HomeProvider>(context)
                      .dropdownVisibilities['showServiceStaff']!,
                  child: _buildServiceStaffDropdown(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Visibility(
                  visible: Provider.of<HomeProvider>(context)
                      .dropdownVisibilities['showKitchenOrder']!,
                  child: Container(
                    height: 56,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (val) {},
                          activeColor: themeData.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text('Kitchen Order'),
                        const SizedBox(width: 4),
                        const Icon(Icons.info_outline,
                            size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    // Defensive check to prevent RangeError
    if (_selectedCustomerId != null &&
        !_customers.any((c) => c['id'] == _selectedCustomerId)) {
      _selectedCustomerId =
          _customers.isNotEmpty ? _customers.first['id'] : null;
    }

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ]),
      child: Row(
        children: [
          Icon(MdiIcons.accountOutline, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownSearch<int>(
              items: _customers.map((customer) {
                return customer['id'] as int;
              }).toList(),
              itemAsString: (int? id) {
                final customer = _customers.firstWhere((c) => c['id'] == id,
                    orElse: () => {'name': ''});
                return customer['name'] ?? '';
              },
              selectedItem: _selectedCustomerId,
              onChanged: (int? value) {
                if (value != null) {
                  final selected = _customers
                      .firstWhere((element) => element['id'] == value);
                  Provider.of<HomeProvider>(context, listen: false)
                      .updateSelectedCustomer(selected);
                  setState(() {
                    _selectedCustomerId = value;
                  });
                }
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
                constraints: BoxConstraints(maxHeight: 250),
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: "Search for a customer",
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterDropdown() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ]),
      child: Row(
        children: [
          Icon(MdiIcons.printerOutline, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: Colors.white,
                isExpanded: true,
                value: _selectedPrinterId,
                items: _printers.map((printer) {
                  return DropdownMenuItem<int>(
                    value: printer['id'],
                    child: Text(printer['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: _printers.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedPrinterId = value;
                        });
                      },
                hint: const Text("Select Printer"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionAgentDropdown() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ]),
      child: Row(
        children: [
          Icon(MdiIcons.accountTieOutline, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: Colors.white,
                isExpanded: true,
                value: _selectedCommissionAgentId,
                items: _commissionAgents.map((agent) {
                  return DropdownMenuItem<int>(
                    value: agent['id'],
                    child: Text(agent['user_full_name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCommissionAgentId = value;
                  });
                },
                hint: const Text("Select Commission Agent"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypesOfServiceDropdown() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ]),
      child: Row(
        children: [
          Icon(MdiIcons.roomServiceOutline, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: Colors.white,
                isExpanded: true,
                value: _selectedTypesOfServiceId,
                items: _typesOfService.map((service) {
                  return DropdownMenuItem<int>(
                    value: service['id'],
                    child: Text(service['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTypesOfServiceId = value;
                  });
                },
                hint: const Text("Select Service"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableDropdown() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ]),
      child: Row(
        children: [
          Icon(MdiIcons.tableFurniture, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: Colors.white,
                isExpanded: true,
                value: _selectedTableId,
                items: _tables.map((table) {
                  return DropdownMenuItem<int>(
                    value: table['id'],
                    child: Text(table['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTableId = value;
                  });
                },
                hint: const Text("Select Table"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStaffDropdown() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ]),
      child: Row(
        children: [
          Icon(MdiIcons.accountHardHat, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: Colors.white,
                isExpanded: true,
                value: _selectedServiceStaffId,
                items: _serviceStaff.map((staff) {
                  return DropdownMenuItem<int>(
                    value: staff['id'],
                    child: Text(staff['user_full_name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceStaffId = value;
                  });
                },
                hint: const Text("Select Staff"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    if (cartLines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Your cart is empty',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: cartLines.length,
      itemBuilder: (context, index) {
        return _buildCartItemCard(cartLines[index]);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
    );
  }

  void _updateCartItemQuantity(
      int lineId, double currentQuantity, double change) {
    double newQuantity = currentQuantity + change;
    if (newQuantity > 0) {
      SellDatabase().update(lineId, {'quantity': newQuantity}).then((_) {
        _getCartLines();
      });
    } else {
      _removeCartItem(lineId);
    }
  }

  void _removeCartItem(int lineId) {
    SellDatabase().deleteSellLine(lineId).then((_) {
      _getCartLines();
      ToastHelper.show(context, "Item removed from cart");
    });
  }

  Widget _buildCartItemCard(Map<String, dynamic> line) {
    double price = double.parse(line['unit_price']?.toString() ?? '0');
    double quantity = line['quantity'] ?? 0;
    double total = price * quantity;
    int lineId = line['id'];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: line['product_image_url'] ?? '',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Image.asset('assets/images/default_product.png'),
                  errorWidget: (context, url, error) =>
                      Image.asset('assets/images/default_product.png'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200, // Constrain the width of the Column
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line['product_name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                        'Code: ${line['sub_sku'] ?? 'N/A'} | Stock: ${line['stock_available'] ?? 'N/A'}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () =>
                          _updateCartItemQuantity(lineId, quantity, -1)),
                  Text(quantity.toStringAsFixed(0),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.green),
                      onPressed: () =>
                          _updateCartItemQuantity(lineId, quantity, 1)),
                ],
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  value: 'Pieces',
                  items: ['Pieces', 'Kg', 'Box'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (_) {},
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: price.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 472),
              SizedBox(
                width: 90,
                child: Text(
                  '$symbol${total.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(MdiIcons.closeCircleOutline, color: Colors.red),
                onPressed: () => _removeCartItem(lineId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Line 1: Items and Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text('${cartLines.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF1E1E1E))),
              const Spacer(),
              const Text('Total :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text('₹${_subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF1E1E1E))),
            ],
          ),
          const Divider(height: 24),

          // Line 2: Other Charges (Horizontally Aligned)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _buildChargeItem(
                  label: 'Discount (-)',
                  value:
                      '${_cartProvider.selectedDiscountType == 'fixed' ? '₹' : ''}${_cartProvider.discountAmount?.toStringAsFixed(2) ?? '0.00'}${_cartProvider.selectedDiscountType == 'percentage' ? '%' : ''}',
                  onInfoTap: () {},
                  onEditTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: _cartProvider,
                        child: const DiscountDialog(),
                      ),
                    );
                  },
                ),
              ),
              Flexible(
                child: _buildChargeItem(
                  label: 'Order Tax (+)',
                  value:
                      '₹${_cartProvider.orderTaxAmount?.toStringAsFixed(2) ?? '0.00'}',
                  onInfoTap: () {},
                  onEditTap: () {
                    _showEditTaxDialog();
                  },
                ),
              ),
              Flexible(
                child: _buildChargeItem(
                  label: 'Shipping (+)',
                  value: '₹${_shippingCharges.toStringAsFixed(2)}',
                  onInfoTap: () {},
                  onEditTap: _showShippingDialog,
                ),
              ),
              Flexible(
                child: _buildChargeItem(
                  label: 'Packing Charge (+)',
                  value: '₹${0.0.toStringAsFixed(2)}',
                  onInfoTap: () {},
                ),
              ),
              Flexible(
                child: _buildChargeItem(
                  label: 'Round Off',
                  value: '₹${_roundOffAmount.toStringAsFixed(2)}',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChargeItem({
    required String label,
    required String value,
    VoidCallback? onInfoTap,
    VoidCallback? onEditTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (onInfoTap != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onInfoTap,
                child: const Icon(Icons.info, color: Colors.blue, size: 16),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E))),
            if (onEditTap != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Edit $label',
                child: InkWell(
                  onTap: onEditTap,
                  child: const Icon(Icons.edit, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ],
        )
      ],
    );
  }

  Widget _buildDropdownField({
    IconData? icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
              )
            ]),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.grey[600]),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchAndFilterHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: (canViewProducts)
                ? (selectedLocationId == 0)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on),
                            Text(AppLocalizations.of(context)
                                .translate('please_set_a_location')),
                          ],
                        ),
                      )
                    : Column(children: [
                        Expanded(
                          child: _productsGrid(),
                        ),
                      ])
                : Center(
                    child: Text(
                      AppLocalizations.of(context).translate('unauthorised'),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildSearchField(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildPillButton(
            'Category',
            Icons.category_outlined,
            true,
            () {
              _showFilterDialog(
                  'category',
                  _categoryMenuItems,
                  (int? value) => setState(() {
                        categoryId = value!;
                        productList(resetOffset: true);
                      }));
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildPillButton(
            'Brands',
            Icons.branding_watermark_outlined,
            false,
            () {
              _showFilterDialog(
                  'brand',
                  _brandsMenuItems,
                  (int? value) => setState(() {
                        brandId = value!;
                        productList(resetOffset: true);
                      }));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPillButton(
      String text, IconData icon, bool isActive, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: isActive ? Colors.white : Colors.blue),
      label: Text(text,
          style: TextStyle(color: isActive ? Colors.white : Colors.blue)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.blue),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  void _showFilterDialog(String title, List<DropdownMenuItem<int>> items,
      Function(int?) onChanged) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select $title'),
            content: DropdownButton<int>(
              items: items,
              dropdownColor: Colors.white,
              onChanged: (value) {
                onChanged(value);
                Navigator.of(context).pop();
              },
            ),
          );
        });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).translate('search_products'),
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onSubmitted: (value) {
        productList(resetOffset: true);
      },
    );
  }

  Widget _productsGrid() {
    return (products.isEmpty)
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty),
                Text('No products found'),
              ],
            ),
          )
        : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _ProductCard(
                product: products[index],
                symbol: symbol,
                onTap: () => onTapProduct(products[index]),
              );
            },
          );
  }

  Widget _buildStickyBottomBar(double totalPayable) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPaymentButton('Draft', Icons.drafts_outlined,
                      onPressed: () => _saveSale('draft')),
                  _buildPaymentButton('Quotation', Icons.request_quote_outlined,
                      onPressed: () => _saveSale('quotation')),
                  _buildPaymentButton('Suspend', Icons.pause_circle_outline,
                      onPressed: () => _saveSale('suspend')),
                  _buildPaymentButton('Credit Sale', Icons.credit_card_outlined,
                      onPressed: () => _goToCheckout('credit_sale')),
                  _buildPaymentButton('Card', Icons.credit_card,
                      onPressed: () => _goToCheckout('card')),
                  _buildPaymentButton('Multiple Pay', Icons.payment_outlined,
                      color: Colors.blue,
                      onPressed: () => _goToCheckout('multiple_pay')),
                  _buildPaymentButton('Cash', Icons.money_outlined,
                      color: Colors.green, onPressed: _handleCashPayment),
                  _buildPaymentButton('Cancel', Icons.cancel_outlined,
                      color: Colors.red,
                      onPressed: _showCancelConfirmationDialog),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(right: 200.0),
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Total Payable: ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '₹ ${totalPayable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return RecentTransactionsDialog();
                },
              );
            },
            child: const Text('Recent Transactions'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(String label, IconData icon,
      {Color? color, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  //add product to cart after scanning barcode
  Future<void> getScannedProduct(String barcode) async {
    if (canMakeSell) {
      var variations = await Variations().get(
          locationId: selectedLocationId,
          barcode: barcode,
          searchTerm: searchController.text);
      if (canAddSell) {
        if (variations.isNotEmpty) {
          dynamic price;
          dynamic product;
          if (variations[0]['selling_price_group'] != null) {
            jsonDecode(variations[0]['selling_price_group']).forEach((element) {
              if (element['key'] == sellingPriceGroupId) {
                price = element['value'];
              }
            });
          }
          product = ProductModel().product(variations[0], price);
          if (product != null && product['stock_available'] > 0) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(AppLocalizations.of(context).translate('added_to_cart')),
              duration: const Duration(seconds: 1),
            ));
            await Sell().addToCart(
                product, argument != null ? argument!['sellId'] : null);
            if (argument != null) {
              selectedLocationId = argument!['locationId'];
            }
            _getCartLines();
          } else {
            if (!mounted) return;
            ToastHelper.show(context,
                AppLocalizations.of(context).translate('out_of_stock'));
          }
        } else {
          if (!mounted) return;
          ToastHelper.show(context,
              AppLocalizations.of(context).translate('no_product_found'));
        }
      } else {
        if (!mounted) return;
        ToastHelper.show(context,
            AppLocalizations.of(context).translate('no_sells_permission'));
      }
    } else {
      if (!mounted) return;
      ToastHelper.show(context,
          AppLocalizations.of(context).translate('no_subscription_found'));
    }
  }

  bool _isAddingToCart = false;

  //onTap product
  Future<void> onTapProduct(Map<String, dynamic> product) async {
    if (_isAddingToCart) return;
    _isAddingToCart = true;

    if (canAddSell) {
      if (product['stock_available'] > 0) {
        if (!mounted) {
          _isAddingToCart = false;
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).translate('added_to_cart')),
          duration: const Duration(seconds: 1),
        ));
        await Sell()
            .addToCart(product, argument != null ? argument!['sellId'] : null);
        if (argument != null) {
          selectedLocationId = argument!['locationId'];
        }
        await _getCartLines();
      } else {
        if (!mounted) {
          _isAddingToCart = false;
          return;
        }
        ToastHelper.show(
            context, AppLocalizations.of(context).translate('out_of_stock'));
      }
    } else {
      if (!mounted) {
        _isAddingToCart = false;
        return;
      }
      ToastHelper.show(context,
          AppLocalizations.of(context).translate('no_sells_permission'));
    }

    _isAddingToCart = false;
  }

  Future<void> setLocationMap() async {
    await System().get('location').then((value) async {
      for (var element in value) {
        if (element['is_active'].toString() == '1') {
          if (mounted) {
            setState(() {
              locationListMap.add({
                'id': element['id'],
                'name': element['name'],
                'selling_price_group_id': element['selling_price_group_id']
              });
            });
          }
        }
      }
      await priceGroupList();
    });
  }

  void setDefaultLocation(dynamic defaultLocation) {
    if (defaultLocation != 0) {
      if (mounted) {
        setState(() {
          selectedLocationId = defaultLocation;
        });
      }
    } else if (locationListMap.length > 1) {
      if (mounted) {
        setState(() {
          selectedLocationId = locationListMap[1]['id'] as int;
        });
      }
    }
  }

  Future<void> _showCartResetDialogForLocation() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(AppLocalizations.of(context).translate('change_location')),
          content: Text(AppLocalizations.of(context)
              .translate('all_items_in_cart_will_be_remove')),
          actions: [
            TextButton(
                onPressed: () {
                  changeLocation = false;
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).translate('no'))),
            TextButton(
                onPressed: () {
                  changeLocation = true;
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).translate('yes')))
          ],
        );
      },
    );
  }

  double get _subtotal {
    if (cartLines.isEmpty) {
      return 0.0;
    }
    return cartLines
        .map<double>((line) =>
            double.parse(line['unit_price']?.toString() ?? '0') *
            (line['quantity'] ?? 0))
        .fold(0.0, (a, b) => a + b);
  }

  double get _totalPayable {
    final discountAmount = _cartProvider.discountAmount ?? 0.0;
    final orderTaxAmount = _cartProvider.orderTaxAmount ?? 0.0;
    double total = _subtotal;

    if (_cartProvider.selectedDiscountType == 'fixed') {
      total -= discountAmount;
    } else if (_cartProvider.selectedDiscountType == 'percentage') {
      total -= (_subtotal * discountAmount / 100);
    }

    total += orderTaxAmount;
    total += _shippingCharges;
    return total;
  }

  void _goToCheckout(String paymentMethod) async {
    if (cartLines.isEmpty) {
      ToastHelper.show(
          context, AppLocalizations.of(context).translate('cart_is_empty'));
      return;
    }
    final result = await Navigator.pushNamed(context, '/checkout',
        arguments: Helper().argument(
            invoiceAmount: _totalPayable,
            subTotal: _subtotal,
            locId: selectedLocationId,
            customerId: Provider.of<HomeProvider>(context, listen: false)
                .selectedCustomer['id'],
            taxId: 0, //TODO: get tax id
            discountType: 'fixed',
            discountAmount: 0));

    if (result == 'sale_completed') {
      await _getCartLines();
      Provider.of<HomeProvider>(context, listen: false).resetCustomer();
      ToastHelper.show(context, "Sale completed successfully");
    }
  }

  Future<Map<String, dynamic>> _prepareSellData(String status) async {
    // Recalculate totals to ensure they are saved correctly
    double subtotal = cartLines.fold(0.0, (sum, line) {
      double price = double.parse(line['unit_price']?.toString() ?? '0');
      double quantity = line['quantity'] ?? 0;
      return sum + (price * quantity);
    });

    double discountValue = 0;
    if (_cartProvider.selectedDiscountType == 'fixed') {
      discountValue = _cartProvider.discountAmount ?? 0.0;
    } else if (_cartProvider.selectedDiscountType == 'percentage') {
      discountValue = (subtotal * (_cartProvider.discountAmount ?? 0.0)) / 100;
    }

    double taxAmount = _cartProvider.orderTaxAmount ?? 0.0;
    double totalPayable = subtotal - discountValue + taxAmount + _shippingCharges;

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    return {
      'transaction_date': DateTime.now().toIso8601String(),
      'contact_id': _selectedCustomerId,
      'invoice_amount': totalPayable.floor().toDouble(),
      'pending_amount': totalPayable.floor().toDouble(),
      'status': status,
      'location_id': selectedLocationId,
      'tax_rate_id': _cartProvider.selectedTaxId,
      'discount_type': _cartProvider.selectedDiscountType,
      'discount_amount': discountValue, // Use calculated value
      'total_before_tax': subtotal, // Add subtotal
      'tax_amount': taxAmount, // Add tax amount
      'shipping_charges': _shippingCharges,
      'service_staff_id': _selectedServiceStaffId,
      'commission_agent': _selectedCommissionAgentId,
      'is_quotation': 0,
    };
  }

  Future<void> _handleCashPayment() async {
    if (cartLines.isEmpty) {
      ToastHelper.show(context, "Cart is empty");
      return;
    }

    // 1. Create the sell
    final sellData = await _prepareSellData('final');
    sellData['invoice_no'] = 'cash-sale-${DateTime.now().millisecondsSinceEpoch}';
    sellData['pending_amount'] = 0.0;
    final saleId = await SellDatabase().storeSell(sellData);

    // 2. Create payment line
    final paymentData = {
      'sell_id': saleId,
      'amount': _totalPayable,
      'method': 'cash',
      'paid_on': DateTime.now().toIso8601String(),
    };
    await PaymentDatabase().store(paymentData);

    // 3. Update sell line status
    await SellDatabase().updateSellLine({'sell_id': saleId, 'is_completed': 1});

    // 4. Sync with API if connected
    if (await Helper().checkConnectivity()) {
      await Sell().createApiSell(sellId: saleId);
    }

    // 5. Print using the new centralized helper
    final saleDetails = (await SellDatabase().getSellBySellId(saleId)).first;
    await Helper()
        .printDocument(saleId, saleDetails['tax_rate_id'] ?? 0, context);

    // 6. Reset cart
    await Sell().resetCart();
    await _getCartLines();
  }

  Future<void> _showPrinterDialog(int sellId, Map<String, dynamic> saleDetails,
      List<Map<String, dynamic>> sellLines, List<dynamic> payment) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PrintReceiptDialog(
          sellId: sellId,
          printers: _printers,
          selectedPrinterId: _selectedPrinterId,
          saleDetails: saleDetails,
          sellLines: sellLines,
          payment: payment,
        );
      },
    );
  }

  Future<void> _showCancelConfirmationDialog({bool isNewSale = false}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isNewSale ? 'New Sale' : 'Cancel Sale'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(isNewSale
                    ? 'Are you sure you want to start a new sale? All items in the cart will be cleared.'
                    : 'Are you sure you want to cancel this sale?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _cancelSale();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _cancelSale() {
    Sell().resetCart();
    _getCartLines();
    Provider.of<HomeProvider>(context, listen: false).resetCustomer();
    ToastHelper.show(context, "Sale cancelled");
  }

  Future<int?> _saveSale(String status) async {
    if (cartLines.isEmpty) {
      if (mounted) {
        ToastHelper.show(
            context, AppLocalizations.of(context).translate('cart_is_empty'));
      }
      return null;
    }

    Map<String, dynamic> sale = await Sell().createSell(
      invoiceNo: '$status-${DateTime.now().millisecondsSinceEpoch}',
      transactionDate: DateTime.now().toIso8601String(),
      contactId: Provider.of<HomeProvider>(context, listen: false)
          .selectedCustomer['id'],
      locId: selectedLocationId,
      saleStatus: status,
      invoiceAmount: _totalPayable,
    );

    int sellId = await SellDatabase().storeSell(sale);
    await SellDatabase().updateSellLine({'sell_id': sellId, 'is_completed': 1});

    if (status != 'final' && mounted) {
      ToastHelper.show(context, 'Sale saved as $status');
      await Sell().resetCart();
      _getCartLines();
      Provider.of<HomeProvider>(context, listen: false).resetCustomer();
    }
    return sellId;
  }

  void _showEditTaxDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Edit Order Tax'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<int>(
                  dropdownColor: Colors.white,
                  value: _cartProvider.selectedTaxId,
                  items: _cartProvider.taxListMap
                      .map<DropdownMenuItem<int>>((Map value) {
                    return DropdownMenuItem<int>(
                      value: value['id'],
                      child: Text(value['name']),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      _cartProvider.setTax(newValue);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Order Tax*',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Update'),
                onPressed: () {
                  if (_cartProvider.selectedTaxId != null) {
                    _cartProvider.updateOrderTax(
                        _cartProvider.selectedTaxId!, _subtotal);
                  }
                  Navigator.of(context).pop();
                  setState(() {});
                },
              ),
            ],
          );
        });
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final String symbol;
  final VoidCallback onTap;

  const _ProductCard(
      {required this.product, required this.symbol, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product['product_image_url'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Image.asset('assets/images/default_product.png'),
                  errorWidget: (context, url, error) =>
                      Image.asset('assets/images/default_product.png'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['display_name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${product['sub_sku'] ?? ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${double.parse(product['unit_price']?.toString() ?? '0').toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
