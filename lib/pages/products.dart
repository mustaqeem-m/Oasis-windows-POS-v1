import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_2/helpers/toast_helper.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/generators.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/product_model.dart';
import '../models/sell.dart';
import '../models/system.dart';
import '../models/variations.dart';

class CustomerSection extends StatelessWidget {
  const CustomerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.person, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Walk-In Customer',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('+1 234 567 890'),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the cart table from 'cart.dart'.
class CartTable extends StatelessWidget {
  final List<Map<String, dynamic>> cartLines;
  final String currencySymbol;

  const CartTable(
      {super.key, required this.cartLines, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            const ListTile(
              title: Text('Cart Items',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: cartLines.map((line) {
                    double price = double.parse(line['unit_price'].toString());
                    int quantity = line['quantity'];
                    double total = price * quantity;
                    return DataRow(cells: [
                      DataCell(Text(line['product_name'] ?? '')),
                      DataCell(Text(quantity.toString())),
                      DataCell(Text(
                          '$currencySymbol${price.toStringAsFixed(2)}')),
                      DataCell(Text(
                          '$currencySymbol${total.toStringAsFixed(2)}')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  List products = [];
  List<Map<String, dynamic>> cartLines = [];
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
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

  List<DropdownMenuItem<int>> _categoryMenuItems = [],
      _subCategoryMenuItems = [],
      _brandsMenuItems = [];
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
  initState() {
    super.initState();
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
    argument = ModalRoute.of(context)!.settings.arguments as Map?;
    //Arguments sellId & locationId is send from edit.
    if (argument != null) {
      Future.delayed(Duration(milliseconds: 200), () {
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
  Future<void> setInitDetails(selectedLocationId) async {
    //check subscription
    final activeSubscriptionDetails = await System().get('active-subscription');
    if (activeSubscriptionDetails.isNotEmpty) {
      setState(() {
        canMakeSell = true;
      });
    } else {
      ToastHelper.show(context,
          AppLocalizations.of(context).translate('no_subscription_found'));
    }
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = value['symbol'] + ' ';
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
  void findSellingPriceGroupId(locId) {
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
      setState(() {
        offset = 0;
        products = <dynamic>[];
      });
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

  Future<void> subCategoryList(parentId) async {
    List<dynamic> subCategories = await System().getSubCategories(parentId);
    _subCategoryMenuItems = [];
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
    final counts =
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
        backgroundColor: themeData.colorScheme.surface,
        appBar: _buildAppBar(),
        body: Row(
          children: [
            Expanded(
              flex: 11, // Left panel takes 55% of the width
              child: _buildLeftPanel(),
            ),
            Expanded(
              flex: 9, // Right panel takes 45% of the width
              child: _buildRightPanel(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomPaymentBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Row(
        children: [
          locations(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                    letterSpacing: 0, fontWeight: 500),
                decoration: InputDecoration(
                  hintText: "Enter product name / SKU / Scan barcode",
                  hintStyle: AppTheme.getTextStyle(
                      themeData.textTheme.titleSmall,
                      letterSpacing: 0,
                      fontWeight: 500),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(MySize.size16!),
                      ),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(MySize.size16!),
                      ),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(MySize.size16!),
                      ),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: themeData.colorScheme.surface,
                  isDense: true,
                  contentPadding: EdgeInsets.only(
                      left: MySize.size16!,
                      right: MySize.size16!,
                      top: MySize.size8!,
                      bottom: MySize.size8!),
                ),
                textCapitalization: TextCapitalization.sentences,
                controller: searchController,
                onEditingComplete: () {
                  productList(resetOffset: true);
                },
              ),
            ),
          ),
          Text(DateTime.now().toString().substring(0, 16)),
        ],
      ),
      actions: [
        IconButton(icon: Icon(Icons.save), onPressed: () {}),
        IconButton(icon: Icon(Icons.print), onPressed: () {}),
        IconButton(icon: Icon(Icons.build), onPressed: () {}),
        IconButton(icon: Icon(Icons.add_shopping_cart), onPressed: () {}),
        IconButton(icon: Icon(Icons.fullscreen), onPressed: () {}),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          CustomerSection(),
          Expanded(
              child: CartTable(
            cartLines: cartLines,
            currencySymbol: symbol,
          )),
          _buildCartOptions(),
          _buildCartTotals(),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildSearchAndScan(),
          _buildFilterButtons(),
          Expanded(
            child: (canViewProducts)
                ? (selectedLocationId == 0)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on),
                            Text(AppLocalizations.of(context)
                                .translate('please_set_a_location')),
                          ],
                        ),
                      )
                    : _productsList()
                : Center(
                    child: Text(
                      AppLocalizations.of(context).translate('unauthorised'),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndScan() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MySize.size8!),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          InkWell(
            onTap: () async {
              var barcode = await Helper().barcodeScan(context);
              await getScannedProduct(barcode);
            },
            child: Container(
              margin: EdgeInsets.only(left: MySize.size8!),
              decoration: BoxDecoration(
                color: themeData.colorScheme.surface,
                borderRadius:
                    BorderRadius.all(Radius.circular(MySize.size16!)),
                boxShadow: [
                  BoxShadow(
                    color: themeData.cardTheme.shadowColor!.withAlpha(48),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              padding: EdgeInsets.all(MySize.size12!),
              child: Icon(
                MdiIcons.barcode,
                color: themeData.colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: () {}, child: Text("Category")),
        ElevatedButton(onPressed: () {}, child: Text("Brand")),
      ],
    );
  }

  Widget _buildCartOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(value: false, onChanged: (val) {}),
              Text("Subscribe?"),
            ],
          ),
          DropdownButtonFormField<String>(
            items: [DropdownMenuItem(child: Text("Select Table"))],
            onChanged: (val) {},
            decoration: InputDecoration(labelText: "Select Table"),
          ),
          DropdownButtonFormField<String>(
            items: [DropdownMenuItem(child: Text("Service Staff"))],
            onChanged: (val) {},
            decoration: InputDecoration(labelText: "Service Staff"),
          ),
          Row(
            children: [
              Checkbox(value: false, onChanged: (val) {}),
              Text("Kitchen Order"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartTotals() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Items Count:"), Text("0")],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Subtotal:"), Text("\$0.00")],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Tax:"), Text("\$0.00")],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPaymentBar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              spacing: 8.0,
              children: [
                ElevatedButton(onPressed: () {}, child: Text("Draft")),
                ElevatedButton(onPressed: () {}, child: Text("Quotation")),
                ElevatedButton(onPressed: () {}, child: Text("Suspend")),
                ElevatedButton(onPressed: () {}, child: Text("Credit Sale")),
                ElevatedButton(onPressed: () {}, child: Text("Card")),
                ElevatedButton(onPressed: () {}, child: Text("Multiple Pay")),
                ElevatedButton(onPressed: () {}, child: Text("Cash")),
                ElevatedButton(
                    onPressed: () {},
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("Cancel")),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Total Payable: \$0.00",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () {}, child: Text("Recent Transactions")),
              ],
            )
          ],
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
            setState(() {
              product = ProductModel().product(value[0], price);
            });
            if (product != null && product['stock_available'] > 0) {
              ToastHelper.show(context,
                  AppLocalizations.of(context).translate('added_to_cart'));
              await Sell().addToCart(
                  product, argument != null ? argument!['sellId'] : null);
              if (argument != null) {
                selectedLocationId = argument!['locationId'];
              }
              _getCartLines();
            } else {
              ToastHelper.show(context,
                  AppLocalizations.of(context).translate('out_of_stock'));
            }
          } else {
            ToastHelper.show(context,
                AppLocalizations.of(context).translate('no_product_found'));
          }
        } else {
          ToastHelper.show(context,
              AppLocalizations.of(context).translate('no_sells_permission'));
        }
      });
    } else {
      ToastHelper.show(context,
          AppLocalizations.of(context).translate('no_subscription_found'));
    }
  }

  Widget _productsList() {
    return (products.isEmpty)
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty),
                Text(AppLocalizations.of(context)
                    .translate('no_products_found')),
              ],
            ),
          )
        : Container(
            child: GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                  bottom: MySize.size16!,
                  left: MySize.size16!,
                  right: MySize.size16!),
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Changed to 2 for the right panel
                mainAxisSpacing: MySize.size16!,
                crossAxisSpacing: MySize.size16!,
                childAspectRatio:
                    findAspectRatio(MediaQuery.of(context).size.width / 2),
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    onTapProduct(index);
                  },
                  child: _ProductGridWidget(
                    name: products[index]['display_name'],
                    image: products[index]['product_image_url'],
                    qtyAvailable: (products[index]['enable_stock'] != 0)
                        ? products[index]['stock_available'].toString()
                        : '-',
                    price:
                        double.parse(products[index]['unit_price'].toString()),
                    symbol: symbol,
                    key: ValueKey(products[index]['id']),
                  ),
                );
              },
            ),
          );
  }

  //onTap product
  Future<void> onTapProduct(int index) async {
    if (canAddSell) {
      if (canMakeSell) {
        if (products[index]['stock_available'] > 0) {
          ToastHelper.show(
              context, AppLocalizations.of(context).translate('added_to_cart'));
          await Sell().addToCart(
              products[index], argument != null ? argument!['sellId'] : null);
          if (argument != null) {
            selectedLocationId = argument!['locationId'];
          }
          _getCartLines();
        } else {
          ToastHelper.show(
              context, AppLocalizations.of(context).translate('out_of_stock'));
        }
      } else {
        ToastHelper.show(context,
            AppLocalizations.of(context).translate('no_sale_permission'));
      }
    } else {
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

  void setDefaultLocation(defaultLocation) {
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

  Widget locations() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedLocationId,
          items: locationListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
                value: value['id'],
                child: SizedBox(
                  width: MySize.screenWidth! * 0.2,
                  child: Text('${value['name']}',
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(fontSize: 15)),
                ));
          }).toList(),
          onTap: () {
            if (locationListMap.length <= 2) {
              canChangeLocation = false;
            }
          },
          onChanged: (int? newValue) async {
            // show a confirmation if there location is changed.
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
                    //reset cart items
                    Sell().resetCart();
                    selectedLocationId = newValue!;
                    //reset all filters & search
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
              ToastHelper.show(
                  context,
                  AppLocalizations.of(context)
                      .translate('cannot_change_location'));
            }
          }),
    );
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
}

class _ProductGridWidget extends StatefulWidget {
  final String? name, image, symbol;
  final String? qtyAvailable;
  final double? price;

  const _ProductGridWidget({
    super.key,
    required this.name,
    required this.image,
    required this.qtyAvailable,
    required this.price,
    required this.symbol,
  });

  @override
  _ProductGridWidgetState createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<_ProductGridWidget> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  @override
  Widget build(BuildContext context) {
    String key = Generator.randomString(10);
    themeData = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: themeData.cardTheme.color,
        borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
        boxShadow: [
          BoxShadow(
            color: themeData.cardTheme.shadowColor!.withAlpha(12),
            blurRadius: 4,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MySize.size2!),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Hero(
                tag: key,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(MySize.size8!),
                      topRight: Radius.circular(MySize.size8!)),
                  child: CachedNetworkImage(
                      width: MediaQuery.of(context).size.width,
                      height: MySize.size140,
                      fit: BoxFit.fitHeight,
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/images/default_product.png'),
                      placeholder: (context, url) =>
                          Image.asset('assets/images/default_product.png'),
                      imageUrl: widget.image ?? ''),
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.only(left: MySize.size2!, right: MySize.size2!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.name!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                        fontWeight: 500, letterSpacing: 0)),
                Container(
                  margin: EdgeInsets.only(top: MySize.size4!),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        widget.symbol! + Helper().formatCurrency(widget.price),
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyMedium,
                            fontWeight: 700,
                            letterSpacing: 0),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: themeData.colorScheme.primary,
                            borderRadius: BorderRadius.all(
                                Radius.circular(MySize.size4!))),
                        padding: EdgeInsets.only(
                            left: MySize.size6!,
                            right: MySize.size8!,
                            top: MySize.size2!,
                            bottom: MySize.getScaledSizeHeight(3.5)),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              MdiIcons.stocking,
                              color: themeData.colorScheme.onPrimary,
                              size: MySize.size12,
                            ),
                            Container(
                              margin: EdgeInsets.only(left: MySize.size4!),
                              child: (widget.qtyAvailable != '-')
                                  ? Text(
                                      Helper()
                                          .formatQuantity(widget.qtyAvailable),
                                      style: AppTheme.getTextStyle(
                                          themeData.textTheme.labelSmall,
                                          fontSize: 11,
                                          color:
                                              themeData.colorScheme.onPrimary,
                                          fontWeight: 600))
                                  : Text('-'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}