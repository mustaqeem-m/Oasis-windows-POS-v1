import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_2/helpers/toast_helper.dart';
import 'package:pos_2/providers/home_provider.dart';
import 'package:provider/provider.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/generators.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/product_model.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  ProductsState createState() => ProductsState();
}

class ProductsState extends State<Products> {
  List products = [];
  List<Map<String, dynamic>> cartLines = [];
  static int themeType = 1;
  late ThemeData themeData;
  bool changeLocation = false,
      canChangeLocation = true,
      canMakeSell = false,
      inStock = true,
      canAddSell = false,
      canViewProducts = false,
      usePriceGroup = true;

  int selectedLocationId = 0,
      categoryId = 0,
      subCategoryId = 0,
      brandId = 0,
      cartCount = 0,
      sellingPriceGroupId = 0,
      offset = 0;
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    themeData = AppTheme.getThemeFromThemeMode(themeType);
    getPermission();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        productList();
      }
    });
    setLocationMap();
    categoryList();
    subCategoryList(categoryId);
    brandList();
    Helper().syncCallLogs();
    _getCartLines();
  }

  Future<void> _getCartLines() async {
    final lines = await Sell().getCartLines();
    if (mounted) {
      setState(() {
        cartLines = lines;
      });
    }
  }

  @override
  Future<void> didChangeDependencies() async {
    argument =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    //Arguments sellId & locationId is send from edit.
    if (argument != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            selectedLocationId = argument!['locationId'];
            canChangeLocation = false;
          });
        }
      });
    } else {
      canChangeLocation = true;
    }
    if (!mounted) return;
    await setInitDetails(selectedLocationId);
    super.didChangeDependencies();
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
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = '${value['symbol']} ';
    });
    setDefaultLocation(selectedLocationId);
    products = [];
    offset = 0;
    productList();
  }

  //Fetch permission from database
  Future<void> getPermission() async {
    if (await Helper().getPermission("direct_sell.access")) {
      canAddSell = true;
    }
    if (await Helper().getPermission("product.view")) {
      canViewProducts = true;
    }
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
    if (resetOffset) {
      if (mounted) {
        setState(() {
          offset = 0;
          products = <dynamic>[];
        });
      }
    }
    offset++;
    //check last sync, if difference is 10 minutes then sync again.
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
    await Variations()
        .get(
            brandId: brandId,
            categoryId: categoryId,
            subCategoryId: subCategoryId,
            inStock: inStock,
            locationId: selectedLocationId,
            searchTerm: searchController.text,
            offset: offset,
            byAlphabets: byAlphabets,
            byPrice: byPrice)
        .then((element) {
      for (var product in element) {
        dynamic price;
        if (product['selling_price_group'] != null) {
          jsonDecode(product['selling_price_group']).forEach((element) {
            if (element['key'] == sellingPriceGroupId) {
              price = double.parse(element['value'].toString());
            }
          });
        }
        if (mounted) {
          setState(() {
            products.add(ProductModel().product(product, price));
          });
        }
      }
    });
  }

  Future<void> categoryList() async {
    List<dynamic> categories = await System().getCategories();
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
    return (width / 2 - MySize.size24!) / ((width / 2 - MySize.size24!) + 60);
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF7F8FC),
        body: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7, // Left panel for cart
                      child: _buildLeftPanel(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3, // Right panel for products
                      child: _buildRightPanel(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildStickyBottomBar(),
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
      child: Row(
        children: [
          // Location Dropdown
          _buildLocationDropdown(),
          const SizedBox(width: 16),

          // Datetime Picker
          _buildDateTimePicker(),
          const Spacer(),

          // Action Buttons
          _buildActionIconButton(Icons.arrow_back, () {}),
          _buildActionIconButton(Icons.close, () {}, color: Colors.red),
          _buildActionIconButton(Icons.person_add_alt_1_outlined, () {
            Navigator.pushNamed(context, '/customer');
          }),
          _buildActionIconButton(Icons.business_center_outlined, () {}),
          _buildActionIconButton(Icons.calculate_outlined, () {}),
          _buildActionIconButton(Icons.undo_outlined, () {}),
          _buildActionIconButton(Icons.minimize, () {}),
          _buildActionIconButton(Icons.fullscreen, () {}),
          const Spacer(),

          // Far Right Buttons
          _buildTextIconButton(
              'Repair', Icons.build_outlined, Colors.lightBlue),
          const SizedBox(width: 30),
          _buildTextIconButton(
              'Add Expense', Icons.add_card_outlined, Colors.transparent,
              borderColor: Colors.black),
        ],
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
      {Color? borderColor}) {
    return TextButton.icon(
      onPressed: () {},
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedLocationId,
          items: locationListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
              value: value['id'],
              child: Text(
                value['name'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
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
            DateFormat('dd MMM, yyyy').format(DateTime.now()),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildDropdownField(
                icon: MdiIcons.accountOutline,
                label: 'Customer',
                value: Provider.of<HomeProvider>(context)
                        .selectedCustomer['name'] ??
                    'Walk-In Customer',
                onTap: () => Navigator.pushNamed(context, '/customer'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                icon: MdiIcons.tagOutline,
                label: 'Price Type',
                value: 'Default Selling Price',
                onTap: () {
                  // TODO: Implement price type selection
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                icon: MdiIcons.printerOutline,
                label: 'Printer Type',
                value: 'Thermal',
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildDropdownField(
                icon: MdiIcons.accountTieOutline,
                label: 'Commission Agent',
                value: 'Select Agent',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                icon: MdiIcons.roomServiceOutline,
                label: 'Types of Service',
                value: 'Select Service',
                onTap: () {},
                trailing: const Icon(Icons.info_outline,
                    size: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                icon: MdiIcons.calendarBlankOutline,
                label: 'Date',
                value: DateFormat('dd MMM, yyyy').format(DateTime.now()),
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildDropdownField(
                icon: MdiIcons.tableFurniture,
                label: 'Table',
                value: 'Select Table',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                icon: MdiIcons.accountHardHat,
                label: 'Service Staff',
                value: 'Select Staff',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: false,
              onChanged: (val) {},
              activeColor: themeData.primaryColor,
            ),
            const Text('Subscribe?'),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 18, color: Colors.grey),
          ],
        ),
      ],
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

  Widget _buildCartItemCard(Map<String, dynamic> line) {
    double price = double.parse(line['unit_price']?.toString() ?? '0');
    double quantity = line['quantity'] ?? 0;
    double total = price * quantity;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line['product_name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                      'Code: ${line['sub_sku'] ?? 'N/A'} | Stock: ${line['stock_available'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: () {
                      // TODO: Decrement quantity
                    }),
                Text(quantity.toStringAsFixed(0),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.green),
                    onPressed: () {
                      // TODO: Increment quantity
                    }),
              ],
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
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
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: Text(
                '$symbol${total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            IconButton(
              icon: Icon(MdiIcons.closeCircleOutline, color: Colors.red),
              onPressed: () {
                // TODO: Remove item
              },
            ),
          ],
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
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${cartLines.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E1E1E))),
              const Spacer(),
              const Text('Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$symbol${_totalPayable.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E1E1E))),
            ],
          ),
          const Divider(height: 24),

          // Line 2: Other Charges (Horizontally Aligned)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChargeItem(
                label: 'Discount (-)',
                value: '$symbol${0.0.toStringAsFixed(2)}',
                onInfoTap: () {},
                onEditTap: () {},
              ),
              _buildChargeItem(
                label: 'Order Tax (+)',
                value: '$symbol${0.0.toStringAsFixed(2)}',
                onInfoTap: () {},
                onEditTap: () {},
              ),
              _buildChargeItem(
                label: 'Shipping (+)',
                value: '$symbol${0.0.toStringAsFixed(2)}',
                onInfoTap: () {},
                onEditTap: () {},
              ),
              _buildChargeItem(
                label: 'Packing Charge (+)',
                value: '$symbol${0.0.toStringAsFixed(2)}',
                onInfoTap: () {},
              ),
              _buildChargeItem(
                label: 'Round Off',
                value: '$symbol${0.0.toStringAsFixed(2)}',
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
              InkWell(
                onTap: onEditTap,
                child: const Icon(Icons.edit, size: 16, color: Colors.grey),
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
    return Column(
      children: [
        _buildFilterHeader(),
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
                  : _productsGrid()
              : Center(
                  child: Text(
                    AppLocalizations.of(context).translate('unauthorised'),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    return Row(
      children: [
        Expanded(
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
            controller: _scrollController,
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
                onTap: () => onTapProduct(index),
              );
            },
          );
  }

  Widget _buildStickyBottomBar() {
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
                      color: Colors.green,
                      onPressed: () => _goToCheckout('cash')),
                  _buildPaymentButton('Cancel', Icons.cancel_outlined,
                      color: Colors.red,
                      onPressed: _showCancelConfirmationDialog),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total Payable:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '$symbol${_totalPayable.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ],
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
      await Variations()
          .get(
              locationId: selectedLocationId,
              barcode: barcode,
              offset: 0,
              searchTerm: searchController.text)
          .then((value) async {
        if (canAddSell) {
          if (value.isNotEmpty) {
            dynamic price;
            dynamic product;
            if (value[0]['selling_price_group'] != null) {
              jsonDecode(value[0]['selling_price_group']).forEach((element) {
                if (element['key'] == sellingPriceGroupId) {
                  price = element['value'];
                }
              });
            }
            setState(() {
              product = ProductModel().product(value[0], price);
            });
            if (product != null && product['stock_available'] > 0) {
              if (!mounted) return;
              ToastHelper.show(context,
                  AppLocalizations.of(context).translate('added_to_cart'));
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
      });
    } else {
      if (!mounted) return;
      ToastHelper.show(context,
          AppLocalizations.of(context).translate('no_subscription_found'));
    }
  }

  //onTap product
  Future<void> onTapProduct(int index) async {
    if (canAddSell) {
      if (canMakeSell) {
        if (products[index]['stock_available'] > 0) {
          if (!mounted) return;
          ToastHelper.show(
              context, AppLocalizations.of(context).translate('added_to_cart'));
          await Sell().addToCart(
              products[index], argument != null ? argument!['sellId'] : null);
          if (argument != null) {
            selectedLocationId = argument!['locationId'];
          }
          _getCartLines();
        } else {
          if (!mounted) return;
          ToastHelper.show(
              context, AppLocalizations.of(context).translate('out_of_stock'));
        }
      } else {
        if (!mounted) return;
        ToastHelper.show(context,
            AppLocalizations.of(context).translate('no_sale_permission'));
      }
    } else {
      if (!mounted) return;
      ToastHelper.show(context,
          AppLocalizations.of(context).translate('no_subscription_found'));
    }
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
    } else if (locationListMap.length == 2) {
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

  double get _totalPayable {
    if (cartLines.isEmpty) {
      return 0.0;
    }
    return cartLines
        .map<double>((line) =>
            double.parse(line['unit_price']?.toString() ?? '0') *
            (line['quantity'] ?? 0))
        .fold(0.0, (a, b) => a + b);
  }

  void _goToCheckout(String paymentMethod) {
    if (cartLines.isEmpty) {
      ToastHelper.show(
          context, AppLocalizations.of(context).translate('cart_is_empty'));
      return;
    }
    Navigator.pushNamed(context, '/checkout',
        arguments: Helper().argument(
            invoiceAmount: _totalPayable,
            locId: selectedLocationId,
            customerId: Provider.of<HomeProvider>(context, listen: false)
                .selectedCustomer['id'],
            taxId: 0, //TODO: get tax id
            discountType: 'fixed',
            discountAmount: 0));
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

  Future<void> _saveSale(String status) async {
    if (cartLines.isEmpty) {
      if (mounted) {
        ToastHelper.show(
            context, AppLocalizations.of(context).translate('cart_is_empty'));
      }
      return;
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

    if (mounted) {
      ToastHelper.show(context, 'Sale saved as $status');
    }
    await Sell().resetCart();
    _getCartLines();
    if (mounted) {
      Provider.of<HomeProvider>(context, listen: false).resetCustomer();
    }
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
                    '$symbol${double.parse(product['unit_price']?.toString() ?? '0').toStringAsFixed(2)}',
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
