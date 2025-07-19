import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_2/helpers/toast_helper.dart';
import 'package:pos_2/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import 'elements.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  CartState createState() => CartState();
}

class CartState extends State<Cart> {
  ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final Map? argument = ModalRoute.of(context)!.settings.arguments as Map?;
    cartProvider.init(argument);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(AppLocalizations.of(context).translate('cart'),
                style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                    fontWeight: 600)),
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  (provider.argument!['sellId'] == null)
                      ? Navigator.pop(context)
                      : Navigator.pushReplacementNamed(context, '/products',
                          arguments: Helper().argument(
                            sellId: provider.argument!['sellId'],
                            locId: provider.argument!['locationId'],
                          ));
                }),
            actions: [
              InkWell(
                onTap: () async {
                  var barcode = await Helper().barcodeScan(context);
                  provider.getScannedProduct(barcode);
                },
                child: Container(
                  margin: EdgeInsets.only(
                      right: MySize.size16!,
                      bottom: MySize.size8!,
                      top: MySize.size8!),
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
                  padding: EdgeInsets.only(
                      left: MySize.size12!, right: MySize.size12!),
                  child: Icon(
                    MdiIcons.barcode,
                    color: themeData.colorScheme.primary,
                  ),
                ),
              ),
              searchDropdown(provider)
            ],
          ),
          body: SingleChildScrollView(
            child: Column(children: <Widget>[
              Container(
                  height: MySize.safeHeight! * 0.65,
                  color: customAppTheme.bgLayer1,
                  child: (provider.cartItems.isNotEmpty)
                      ? itemList(provider)
                      : Center(
                          child: Text(AppLocalizations.of(context)
                              .translate('add_item_to_cart')))),
              Divider(),
              Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(
                        left: MySize.size24!, right: MySize.size24!),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                            '${AppLocalizations.of(context).translate('sub_total')} : ',
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.titleMedium,
                              fontWeight: 700,
                              color: themeData.colorScheme.onSurface,
                            )),
                        Text(
                            provider.symbol +
                                Helper().formatCurrency(
                                    provider.calculateSubTotal()),
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.titleMedium,
                              fontWeight: 700,
                              color: themeData.colorScheme.onSurface,
                            )),
                      ],
                    ),
                  )
                ],
              ),
              Container(
                padding: EdgeInsets.only(
                    left: MySize.size24!, right: MySize.size24!),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${AppLocalizations.of(context).translate('discount')} : ',
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          color: themeData.colorScheme.onSurface,
                          fontWeight: 600,
                          muted: true),
                    ),
                    discount(provider),
                    Expanded(
                      child: SizedBox(
                        height: MySize.size50,
                        child: TextFormField(
                          controller: provider.discountController,
                          decoration: InputDecoration(
                            prefix: Text((provider.selectedDiscountType ==
                                    'fixed')
                                ? provider.symbol
                                : ''),
                            labelText: AppLocalizations.of(context)
                                .translate('discount_amount'),
                            border: themeData.inputDecorationTheme.border,
                            enabledBorder:
                                themeData.inputDecorationTheme.border,
                            focusedBorder:
                                themeData.inputDecorationTheme.focusedBorder,
                          ),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.titleSmall,
                              fontWeight: 400,
                              letterSpacing: -0.2),
                          textAlign: TextAlign.end,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^(\d+)?\.?\d{0,2}'))
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            provider.updateDiscount(value);
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                    left: MySize.size24!, right: MySize.size24!),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${AppLocalizations.of(context).translate('tax')} : ',
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          color: themeData.colorScheme.onSurface,
                          fontWeight: 600,
                          muted: true),
                    ),
                    taxes(provider),
                    Text(
                      '${AppLocalizations.of(context).translate('total')} : ',
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.titleMedium,
                        fontWeight: 700,
                        color: themeData.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                        provider.symbol +
                            Helper().formatCurrency(provider.calculateSubtotal(
                                provider.selectedTaxId,
                                provider.selectedDiscountType,
                                provider.discountAmount)),
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleMedium,
                          fontWeight: 700,
                          color: themeData.colorScheme.onSurface,
                          letterSpacing: 0,
                        ))
                  ],
                ),
              ),
              (provider.canAddServiceStaff)
                  ? Container(
                      padding: EdgeInsets.only(
                          left: MySize.size24!, right: MySize.size24!),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Service staff : ",
                            style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                color: themeData.colorScheme.onSurface,
                                fontWeight: 600,
                                muted: true),
                          ),
                          serviceStaffs(provider)
                        ],
                      ),
                    )
                  : Container(),
            ]),
          ),
          bottomNavigationBar: Visibility(
            visible:
                (provider.cartItems.isNotEmpty && provider.proceedNext == true),
            child: cartBottomBar(
                '/customer',
                AppLocalizations.of(context).translate('customer'),
                context,
                Helper().argument(
                    locId: provider.argument!['locationId'],
                    taxId: provider.selectedTaxId,
                    serviceStaff: provider.selectedServiceStaff,
                    discountType: provider.selectedDiscountType,
                    discountAmount: provider.discountAmount,
                    invoiceAmount: provider.calculateSubtotal(
                        provider.selectedTaxId,
                        provider.selectedDiscountType,
                        provider.discountAmount),
                    sellId: provider.argument!['sellId'],
                    isQuotation: provider.argument!['is_quotation'],
                    customerId: (provider.argument!['sellId'] != null)
                        ? provider.selectedContactId
                        : null)),
          ),
        );
      },
    );
  }

  Widget searchDropdown(CartProvider provider) {
    return Container(
      margin: EdgeInsets.only(right: MySize.size10!, top: MySize.size8!),
      width: MySize.screenWidth! * 0.45,
      child: TextFormField(
        style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
            letterSpacing: 0, fontWeight: 500),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate('search'),
          hintStyle: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
              letterSpacing: 0, fontWeight: 500),
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
          prefixIcon: Icon(
            MdiIcons.magnify,
            size: MySize.size22,
            color: themeData.colorScheme.onSurface.withAlpha(150),
          ),
          isDense: true,
          contentPadding: EdgeInsets.only(right: MySize.size16!),
        ),
        textCapitalization: TextCapitalization.sentences,
        controller: provider.searchController,
        onEditingComplete: () async {
          await provider
              .getSearchItemList(provider.searchController.text)
              .then((value) => itemDialog(value, provider));
          FocusScope.of(context).requestFocus(FocusNode());
        },
      ),
    );
  }

  void itemDialog(List items, CartProvider provider) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: customAppTheme.bgLayer1,
          content: Container(
            color: customAppTheme.bgLayer1,
            height: MySize.screenHeight! * 0.8,
            width: MySize.screenWidth! * 0.8,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: (items.isNotEmpty) ? items.length : 0,
                itemBuilder: ((context, index) {
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.all(MySize.size4!),
                    child: ListTile(
                      title: Text(items[index]['display_name']),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            provider.symbol +
                                Helper()
                                    .formatCurrency(items[index]['unit_price']),
                            style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyMedium,
                                fontWeight: 700,
                                letterSpacing: 0),
                          ),
                          Container(
                            width: MySize.size80,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Icon(
                                  MdiIcons.stocking,
                                  color: themeData.colorScheme.onPrimary,
                                  size: MySize.size12,
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: MySize.size4!),
                                  child: Text(
                                      Helper().formatQuantity(
                                          items[index]['stock_available']),
                                      style: AppTheme.getTextStyle(
                                          themeData.textTheme.bodySmall,
                                          fontSize: 11,
                                          color:
                                              themeData.colorScheme.onPrimary,
                                          fontWeight: 600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)
                                .translate('added_to_cart'));
                        await Sell().addToCart(
                            items[index],
                            provider.argument != null
                                ? provider.argument!['sellId']
                                : null);
                        provider.cartList();
                      },
                    ),
                  );
                })),
          ),
        );
      },
    );
  }

  Widget itemList(CartProvider provider) {
    int themeType = 1;
    ThemeData themeData;
    CustomAppTheme customAppTheme;
    themeData = AppTheme.getThemeFromThemeMode(themeType);
    customAppTheme = AppTheme.getCustomAppTheme(themeType);

    return ListView.builder(
      shrinkWrap: true,
      itemCount: provider.cartItems.length,
      padding: EdgeInsets.only(
        top: MySize.size16!,
      ),
      itemBuilder: (context, index) {
        return Padding(
            padding: EdgeInsets.only(
                left: MySize.size8!,
                right: MySize.size8!,
                bottom: MySize.size8!),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      blurRadius: MySize.size8!,
                      color: customAppTheme.shadowColor,
                      offset: Offset(0, MySize.size4!))
                ],
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          color: themeData.cardTheme.shadowColor!.withAlpha(10),
                          blurRadius: MySize.size16!)
                    ],
                    color: customAppTheme.bgLayer1,
                    borderRadius:
                        BorderRadius.all(Radius.circular(MySize.size16!))),
                padding: EdgeInsets.only(right: MySize.size16!),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(MySize.size8!),
                      child: Text(
                        provider.cartItems[index]['name'],
                        overflow: (provider.editItem == index)
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyLarge,
                            color: themeData.colorScheme.onSurface,
                            fontWeight: 600),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(left: MySize.size20!),
                            child: Column(
                              children: [
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                          Text(
                                            provider.symbol +
                                                Helper().formatCurrency(
                                                    provider.cartItems[index]
                                                        ['unit_price']),
                                            style: AppTheme.getTextStyle(
                                                themeData.textTheme.bodyLarge,
                                                color: themeData
                                                    .colorScheme.onSurface,
                                                fontWeight: 600,
                                                letterSpacing: -0.2,
                                                muted: true),
                                          ),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                    '${AppLocalizations.of(context).translate('total')} : ${provider.symbol}${Helper().formatCurrency((double.parse(provider.calculateInlineUnitPrice(provider.cartItems[index]['unit_price'], provider.cartItems[index]['tax_rate_id'], provider.cartItems[index]['discount_type'], provider.cartItems[index]['discount_amount'])) * provider.cartItems[index]['quantity']))}'),
                                              ]),
                                          Row(
                                            children: [
                                              IconButton(
                                                  icon: Icon(
                                                    MdiIcons.pencil,
                                                    size: MySize.size20,
                                                  ),
                                                  color: themeData
                                                      .colorScheme.onSurface,
                                                  onPressed: () {
                                                    (provider.editItem == index)
                                                        ? provider
                                                            .setEditItem(null)
                                                        : provider
                                                            .setEditItem(index);
                                                  }),
                                              IconButton(
                                                  icon: Icon(MdiIcons.delete,
                                                      size: MySize.size20),
                                                  color: themeData
                                                      .colorScheme.onSurface,
                                                  onPressed: () {
                                                    showDialog(
                                                      barrierDismissible: true,
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return AlertDialog(
                                                          title: Row(
                                                            children: <Widget>[
                                                              Padding(
                                                                padding: EdgeInsets
                                                                    .all(MySize
                                                                        .size5!),
                                                                child: Icon(
                                                                  MdiIcons
                                                                      .alertCircle,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                              Text(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'delete_item_message'),
                                                                style: AppTheme.getTextStyle(
                                                                    themeData
                                                                        .textTheme
                                                                        .titleLarge,
                                                                    color: themeData
                                                                        .colorScheme
                                                                        .onSurface,
                                                                    fontWeight:
                                                                        600),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ],
                                                          ),
                                                          actions: <Widget>[
                                                            TextButton(
                                                                onPressed: () {
                                                                  provider.deleteCartItem(
                                                                      provider.cartItems[index]
                                                                          [
                                                                          'variation_id'],
                                                                      provider.cartItems[index]
                                                                          [
                                                                          'product_id'],
                                                                      sellId:
                                                                          provider.argument!['sellId']);
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text(AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'yes'))),
                                                            TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text(AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'no')))
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  })
                                            ],
                                          )
                                        ])),
                                    Container(
                                        alignment: Alignment.centerRight,
                                        width: MySize.screenWidth! * 0.25,
                                        height: MySize.screenHeight! * 0.05,
                                        child: (provider.editItem != index)
                                            ? Text(
                                                "${AppLocalizations.of(context).translate('quantity')}:${provider.cartItems[index]['quantity'].toString()}")
                                            : TextFormField(
                                                controller: (provider.editItem !=
                                                        index)
                                                    ? TextEditingController(
                                                        text: provider
                                                                .cartItems[
                                                            index]['quantity']
                                                            .toString())
                                                    : null,
                                                initialValue:
                                                    (provider.editItem == index)
                                                        ? provider
                                                                .cartItems[
                                                            index]['quantity']
                                                            .toString()
                                                        : null,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp(
                                                          r'^(\d+)?\.?\d{0,2}'))
                                                ],
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                                textAlign: TextAlign.end,
                                                decoration: InputDecoration(
                                                  labelText: AppLocalizations
                                                          .of(context)
                                                      .translate('quantity'),
                                                ),
                                                onChanged: (newQuantity) {
                                                  provider.updateQuantity(
                                                      provider.cartItems[index]
                                                          ['id'],
                                                      double.parse(
                                                          newQuantity),
                                                      provider.cartItems[index][
                                                          'stock_available']);
                                                },
                                              )),
                                    Container(
                                      margin:
                                          EdgeInsets.only(left: MySize.size24!),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          InkWell(
                                            onTap: () {
                                              provider.incrementQuantity(
                                                  provider.cartItems[index]
                                                      ['id'],
                                                  provider.cartItems[index]
                                                      ['quantity'],
                                                  provider.cartItems[index]
                                                      ['stock_available']);
                                            },
                                            child: Container(
                                              padding:
                                                  EdgeInsets.all(MySize.size6!),
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      customAppTheme.bgLayer3,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: themeData
                                                            .cardTheme
                                                            .shadowColor!
                                                            .withAlpha(8),
                                                        blurRadius:
                                                            MySize.size8!)
                                                  ]),
                                              child: Icon(
                                                MdiIcons.plus,
                                                size: MySize.size20,
                                                color: themeData
                                                    .colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              provider.decrementQuantity(
                                                  provider.cartItems[index]
                                                      ['id'],
                                                  provider.cartItems[index]
                                                      ['quantity']);
                                            },
                                            child: Container(
                                              padding:
                                                  EdgeInsets.all(MySize.size6!),
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      customAppTheme.bgLayer3,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: themeData
                                                            .cardTheme
                                                            .shadowColor!
                                                            .withAlpha(10),
                                                        blurRadius:
                                                            MySize.size8!)
                                                  ]),
                                              child: Icon(
                                                MdiIcons.minus,
                                                size: MySize.size20,
                                                color: themeData
                                                    .colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Visibility(
                                    visible: (provider.editItem == index),
                                    child: edit(
                                        provider.cartItems[index], provider)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget edit(index, CartProvider provider) {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              (provider.canEditPrice)
                  ? SizedBox(
                      width: MySize.size160,
                      height: MySize.size50,
                      child: TextFormField(
                          initialValue: index['unit_price'].toStringAsFixed(2),
                          decoration: InputDecoration(
                            prefix: Text(provider.symbol),
                            labelText: AppLocalizations.of(context)
                                .translate('unit_price'),
                            border: themeData.inputDecorationTheme.border,
                            enabledBorder:
                                themeData.inputDecorationTheme.border,
                            focusedBorder:
                                themeData.inputDecorationTheme.focusedBorder,
                          ),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.titleSmall,
                              fontWeight: 400,
                              letterSpacing: -0.2),
                          textAlign: TextAlign.end,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^(\d+)?\.?\d{0,2}'))
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (newValue) {
                            double value = Helper().validateInput(newValue);
                            SellDatabase()
                                .update(index['id'], {'unit_price': '$value'});
                            provider.cartList();
                          }),
                    )
                  : Container(),
              (provider.canEditDiscount)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                            '${AppLocalizations.of(context).translate('discount_type')} : '),
                        inLineDiscount(index, provider),
                      ],
                    )
                  : Container(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              (provider.canEditDiscount)
                  ? SizedBox(
                      width: MySize.size160,
                      height: MySize.size50,
                      child: TextFormField(
                          initialValue: index['discount_amount'].toString(),
                          decoration: InputDecoration(
                            prefix: Text(provider.symbol),
                            labelText: AppLocalizations.of(context)
                                .translate('discount_amount'),
                            border: themeData.inputDecorationTheme.border,
                            enabledBorder:
                                themeData.inputDecorationTheme.border,
                            focusedBorder:
                                themeData.inputDecorationTheme.focusedBorder,
                          ),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.titleSmall,
                              fontWeight: 400,
                              letterSpacing: -0.2),
                          textAlign: TextAlign.end,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^(\d+)?\.?\d{0,2}'))
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (newValue) {
                            double value = Helper().validateInput(newValue);
                            SellDatabase().update(
                                index['id'], {'discount_amount': '$value'});
                            provider.cartList();
                          }),
                    )
                  : Container(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${AppLocalizations.of(context).translate('tax')} : '),
                  inLineTax(index, provider),
                ],
              ),
            ],
          ),
          (provider.canAddInLineServiceStaff)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Service staff' ' : '),
                        inLineServiceStaff(index, provider),
                      ],
                    )
                  ],
                )
              : Container(),
        ],
      ),
    );
  }

  Widget inLineServiceStaff(index, CartProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: (index['res_service_staff_id'] != null)
              ? index['res_service_staff_id']
              : 0,
          items:
              provider.serviceStaffListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
                value: value['id'],
                child: Text(
                  value['name'],
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ));
          }).toList(),
          onChanged: (newValue) {
            SellDatabase().update(index['id'],
                {'res_service_staff_id': (newValue == 0) ? null : newValue});
            provider.cartList();
          }),
    );
  }

  Widget inLineTax(index, CartProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: (index['tax_rate_id'] != null) ? index['tax_rate_id'] : 0,
          items: provider.taxListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
                value: value['id'],
                child: Text(
                  value['name'],
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ));
          }).toList(),
          onChanged: (newValue) {
            SellDatabase().update(index['id'],
                {'tax_rate_id': (newValue == 0) ? null : newValue});
            provider.cartList();
          }),
    );
  }

  Widget inLineDiscount(index, CartProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: index['discount_type'],
          items: <String>['fixed', 'percentage']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            SellDatabase().update(index['id'], {'discount_type': '$newValue'});
            provider.cartList();
          }),
    );
  }

  Widget discount(CartProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: provider.selectedDiscountType,
          items: <String>['fixed', 'percentage']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            provider.setDiscountType(newValue.toString());
          }),
    );
  }

  Widget taxes(CartProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: provider.selectedTaxId,
          items: provider.taxListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
                value: value['id'],
                child: Text(
                  value['name'],
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ));
          }).toList(),
          onChanged: (newValue) {
            provider.setTax(int.parse(newValue.toString()));
          }),
    );
  }

  Widget serviceStaffs(CartProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: provider.selectedServiceStaff,
          items:
              provider.serviceStaffListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
                value: value['id'],
                child: Text(
                  value['name'],
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ));
          }).toList(),
          onChanged: (newValue) {
            provider.setServiceStaff(int.parse(newValue.toString()));
          }),
    );
  }
}