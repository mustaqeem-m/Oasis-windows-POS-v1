import 'dart:async';

// import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_2/components/shipping_modal.dart';
import 'package:pos_2/helpers/toast_helper.dart';

import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/paymentDatabase.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import 'login.dart';

class CheckOut extends StatefulWidget {
  const CheckOut({super.key});

  @override
  CheckOutState createState() => CheckOutState();
}

class CheckOutState extends State<CheckOut> {
  List<Map> paymentMethods = [];
  int? sellId;
  double totalPaying = 0.0;
  String symbol = '',
      invoiceType = "Mobile",
      transactionDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  Map? argument;
  List<Map> payments = [],
      paymentAccounts = [
        {'id': null, 'name': "None"}
      ];
  List<int> deletedPaymentId = [];
  late Map<String, dynamic> paymentLine;
  List sellDetail = [];
  double invoiceAmount = 0.00, pendingAmount = 0.00, changeReturn = 0.00;
  TextEditingController dateController = TextEditingController(),
      saleNote = TextEditingController(),
      staffNote = TextEditingController(),
      shippingDetails = TextEditingController(),
      shippingCharges = TextEditingController();
  String? shippingAddress, shippingStatus, deliveredTo, deliveryPerson;
  bool _printInvoice = true,
      printWebInvoice = false,
      saleCreated = false,
      isLoading = false;
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    getInitDetails();
  }

  Future<void> getInitDetails() async {
    setState(() {
      isLoading = true;
    });
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = value['symbol'];
    });
  }

  Future<void> setPaymentAccounts() async {
    List payments =
        await System().get('payment_method', argument!['locationId']);
    await System().getPaymentAccounts().then((value) {
      for (var element in value) {
        List<String> accIds = [];
        //check if payment account is assigned to any payment method
        // of selected location.
        for (var paymentMethod in payments) {
          if ((paymentMethod['account_id'].toString() ==
                  element['id'].toString()) &&
              !accIds.contains(element['id'].toString())) {
            setState(() {
              paymentAccounts
                  .add({'id': element['id'], 'name': element['name']});
            });
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    argument = ModalRoute.of(context)!.settings.arguments as Map?;
    invoiceAmount = argument!['invoiceAmount'];
    setPaymentAccounts().then((value) {
      if (argument!['sellId'] == null) {
        setPaymentDetails().then((value) {
          if (payments.isEmpty) {
            payments.add({
              'amount': invoiceAmount,
              'method': paymentMethods.isNotEmpty
                  ? paymentMethods[0]['name']
                  : 'cash',
              'note': '',
              'account_id': paymentMethods.isNotEmpty
                  ? paymentMethods[0]['account_id']
                  : null,
            });
          }
          calculateMultiPayment();
        });
      } else {
        setPaymentDetails().then((value) {
          onEdit(argument!['sellId']);
        });
      }
    });
    setState(() {
      isLoading = false;
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    staffNote.dispose();
    saleNote.dispose();
    super.dispose();
  }

  Future<void> onEdit(sellId) async {
    sellDetail = await SellDatabase().getSellBySellId(sellId);
    this.sellId = argument!['sellId'];
    await SellDatabase().getSellBySellId(sellId).then((value) {
      shippingCharges.text = value[0]['shipping_charges'].toString();
      shippingDetails.text = value[0]['shipping_details'] ?? '';
      saleNote.text = value[0]['sale_note'] ?? '';
      staffNote.text = value[0]['staff_note'] ?? '';
      invoiceAmount =
          argument!['invoiceAmount'] + double.parse(shippingCharges.text);
    });
    payments = [];
    List paymentLines = await PaymentDatabase().get(sellId, allColumns: true);
    for (var element in paymentLines) {
      if (element['is_return'] == 0) {
        payments.add({
          'id': element['id'],
          'amount': element['amount'],
          'method': element['method'],
          'note': element['note'],
          'account_id': element['account_id']
        });
      }
    }
    calculateMultiPayment();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).translate('checkout'),
              style: AppTheme.getTextStyle(themeData.textTheme.titleLarge!,
                  fontWeight: 600)),
        ),
        body: SingleChildScrollView(
          child:
              (isLoading) ? Helper().loadingIndicator(context) : paymentBox(),
        ));
  }

  //payment widget
  Widget paymentBox() {
    if (paymentMethods.isEmpty && payments.isEmpty) {
      return Center(
        child: Text('No payment methods available.'),
      );
    }
    return Container(
      margin: EdgeInsets.all(MySize.size3!),
      child: Column(
        children: <Widget>[
          ListView.builder(
              physics: ScrollPhysics(),
              shrinkWrap: true,
              itemCount: payments.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(MySize.size5!),
                  shadowColor: Colors.blue,
                  child: Padding(
                    padding: EdgeInsets.all(MySize.size8!),
                    child: Column(children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                  '${AppLocalizations.of(context).translate('amount')} : ',
                                  style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodyLarge!,
                                      color: themeData.colorScheme.onSurface,
                                      fontWeight: 600,
                                      muted: true)),
                              SizedBox(
                                  height: MySize.size40,
                                  width: MySize.safeWidth! * 0.50,
                                  child: TextFormField(
                                      decoration: InputDecoration(
                                        prefix: Text(symbol),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      textAlign: TextAlign.end,
                                      initialValue: payments[index]['amount']
                                          .toStringAsFixed(2),
                                      //input formatter will allow only 2 digits after decimal
                                      inputFormatters: [
                                        // ignore: deprecated_member_use
                                        FilteringTextInputFormatter(
                                            RegExp(r'^(\d+)?\.?\d{0,2}'),
                                            allow: true)
                                      ],
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        payments[index]['amount'] =
                                            Helper().validateInput(value);
                                        calculateMultiPayment();
                                      }))
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: MySize.size6!),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: <Widget>[
                              Text(
                                  '${AppLocalizations.of(context).translate('payment_method')} : ',
                                  style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodyLarge!,
                                      color: themeData.colorScheme.onSurface,
                                      fontWeight: 600,
                                      muted: true)),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: themeData.colorScheme.onSurface,
                                      width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton(
                                      dropdownColor:
                                          themeData.colorScheme.surface,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                      ),
                                      value: payments[index]['method'],
                                      //index['tax_rate_id'],
                                      items: paymentMethods
                                          .map<DropdownMenuItem<String>>(
                                              (Map value) {
                                        return DropdownMenuItem<String>(
                                          value: value['name'],
                                          child: SizedBox(
                                            width: MySize.screenWidth! * 0.35,
                                            child: Text(value['value'],
                                                softWrap: true,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.getTextStyle(
                                                    themeData
                                                        .textTheme.bodyLarge!,
                                                    color: themeData
                                                        .colorScheme.onSurface,
                                                    fontWeight: 800,
                                                    muted: true)),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        for (var element in paymentMethods) {
                                          if (element['name'] == newValue) {
                                            setState(() {
                                              payments[index]['method'] =
                                                  newValue;
                                              payments[index]['account_id'] =
                                                  element['account_id'];
                                            });
                                          }
                                        }
                                      }),
                                ),
                              )
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              Text(
                                  '${AppLocalizations.of(context).translate('payment_account')} : ',
                                  style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodyLarge!,
                                      color: themeData.colorScheme.onSurface,
                                      fontWeight: 600,
                                      muted: true)),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: themeData.colorScheme.onSurface,
                                      width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton(
                                      dropdownColor:
                                          themeData.colorScheme.surface,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                      ),
                                      value: payments[index]['account_id'],
                                      //index['tax_rate_id'],
                                      items: paymentAccounts
                                          .map<DropdownMenuItem<int>>(
                                              (Map value) {
                                        return DropdownMenuItem<int>(
                                          value: value['id'],
                                          child: SizedBox(
                                            width: MySize.screenWidth! * 0.35,
                                            child: Text(value['name'],
                                                softWrap: true,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.getTextStyle(
                                                    themeData
                                                        .textTheme.bodyLarge!,
                                                    color: themeData
                                                        .colorScheme.onSurface,
                                                    fontWeight: 800,
                                                    muted: true)),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        setState(() {
                                          payments[index]['account_id'] =
                                              newValue;
                                        });
                                      }),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: MySize.safeWidth! * 0.8,
                            child: TextFormField(
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)
                                        .translate('payment_note'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    )),
                                onChanged: (value) {
                                  payments[index]['note'] = value;
                                }),
                          ),
                          Expanded(
                              child: (index > 0)
                                  ? IconButton(
                                      icon: Icon(
                                        MdiIcons.deleteForeverOutline,
                                        size: MySize.size40,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        alertConfirm(context, index);
                                      })
                                  : Container())
                        ],
                      ),
                    ]),
                  ),
                );
              }),
          Card(
            margin: EdgeInsets.all(MySize.size5!),
            child: Container(
              padding: EdgeInsets.all(MySize.size5!),
              child: Column(
                children: <Widget>[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: themeData.colorScheme.primary,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        payments.add({
                          'amount': pendingAmount,
                          'method': paymentMethods[0]['name'],
                          'note': '',
                          'account_id': paymentMethods[0]['account_id'],
                        });
                        calculateMultiPayment();
                      });
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('add_payment'),
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.titleMedium!,
                        fontWeight: 700,
                        color: themeData.colorScheme.primary,
                      ),
                    ),
                  ),
                  _buildShippingSection(),
                  Container(
                    child: GridView.count(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        crossAxisCount: 2,
                        padding: EdgeInsets.only(
                            left: MySize.size16!,
                            right: MySize.size16!,
                            top: MySize.size16!),
                        mainAxisSpacing: MySize.size16!,
                        childAspectRatio: 8 / 3,
                        crossAxisSpacing: MySize.size16!,
                        children: <Widget>[
                          block(
                            amount: Helper().formatCurrency(invoiceAmount),
                            subject:
                                '${AppLocalizations.of(context).translate('total_payble')} : ',
                            backgroundColor: Colors.blue,
                            textColor: themeData.colorScheme.onSurface,
                          ),
                          block(
                            amount: Helper().formatCurrency(totalPaying),
                            subject:
                                '${AppLocalizations.of(context).translate('total_paying')} : ',
                            backgroundColor: Colors.red,
                            textColor: themeData.colorScheme.onSurface,
                          ),
                          block(
                            amount: Helper().formatCurrency(changeReturn),
                            subject:
                                '${AppLocalizations.of(context).translate('change_return')} : ',
                            backgroundColor: Colors.green,
                            textColor: (changeReturn >= 0.01)
                                ? Colors.red
                                : themeData.colorScheme.onSurface,
                          ),
                          block(
                            amount: Helper().formatCurrency(pendingAmount),
                            subject:
                                '${AppLocalizations.of(context).translate('balance')} : ',
                            backgroundColor: Colors.orange,
                            textColor: (pendingAmount >= 0.01)
                                ? Colors.red
                                : themeData.colorScheme.onSurface,
                          ),
                        ]),
                  ),
                  Padding(
                    padding: EdgeInsets.all(MySize.size8!),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(children: <Widget>[
                              Text(
                                  '${AppLocalizations.of(context).translate('sell_note')} : ',
                                  style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodyLarge!,
                                      color: themeData.colorScheme.onSurface,
                                      fontWeight: 600,
                                      muted: true)),
                              SizedBox(
                                  height: MySize.size80,
                                  width: MySize.screenWidth! * 0.40,
                                  child: TextFormField(
                                    controller: saleNote,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ))
                            ]),
                            Column(
                              children: <Widget>[
                                Text(
                                    '${AppLocalizations.of(context).translate('staff_note')} : ',
                                    style: AppTheme.getTextStyle(
                                        themeData.textTheme.bodyLarge!,
                                        color: themeData.colorScheme.onSurface,
                                        fontWeight: 600,
                                        muted: true)),
                                SizedBox(
                                  height: MySize.size80,
                                  width: MySize.screenWidth! * 0.40,
                                  child: TextFormField(
                                    controller: staffNote,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // GestureDetector(onTap: () {setState(() {shareInvoice = !shareInvoice;_printInvoice = !_printInvoice;});}, child: Row(children: <Widget>[Checkbox(value: shareInvoice, onChanged: (newValue) {setState(() {shareInvoice = !shareInvoice;_printInvoice = !_printInvoice;});}), Text("Share invoice : ", /* "${AppLocalizations.of(context).translate('print_invoice')} : ",*/style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge, color: themeData.colorScheme.onBackground, fontWeight: 600, muted: true))],),), GestureDetector(onTap: () {setState(() {shareInvoice = !shareInvoice;_printInvoice = !_printInvoice;});}, child: Row(children: <Widget>[Checkbox(value: _printInvoice, onChanged: (newValue) {setState(() {shareInvoice = !shareInvoice;_printInvoice = !_printInvoice;});}), Text("${AppLocalizations.of(context).translate('print_invoice')} : ", style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge, color: themeData.colorScheme.onBackground, fontWeight: 600, muted: true))],),),
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Radio(
                                      value: "Mobile",
                                      groupValue: invoiceType,
                                      onChanged: (value) {
                                        setState(() {
                                          invoiceType = value.toString();
                                          printWebInvoice = false;
                                        });
                                      },
                                      toggleable: true,
                                    ),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .translate('mobile_layout'),
                                        maxLines: 2,
                                        style: AppTheme.getTextStyle(
                                            themeData.textTheme.bodyMedium!,
                                            color:
                                                themeData.colorScheme.onSurface,
                                            fontWeight: 600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Radio(
                                      value: "Web",
                                      groupValue: invoiceType,
                                      onChanged: (value) async {
                                        if (await Helper()
                                            .checkConnectivity()) {
                                          setState(() {
                                            invoiceType = value.toString();
                                            printWebInvoice = true;
                                          });
                                        } else {
                                          // Fluttertoast.showToast(
                                          //     msg: AppLocalizations.of(context)
                                          //         .translate(
                                          //             'check_connectivity'));
                                          ToastHelper.show(
                                              context,
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'check_connectivity'));
                                        }
                                      },
                                      toggleable: true,
                                    ),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .translate('web_layout'),
                                        maxLines: 2,
                                        style: AppTheme.getTextStyle(
                                            themeData.textTheme.bodyMedium!,
                                            color:
                                                themeData.colorScheme.onSurface,
                                            fontWeight: 600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeData.colorScheme.onPrimary,
                                    elevation: 5),
                                onPressed: () {
                                  _printInvoice = false;
                                  if (pendingAmount >= 0.01) {
                                    alertPending(context);
                                  } else {
                                    if (!saleCreated) {
                                      onSubmit();
                                    }
                                  }
                                },
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('finalize_n_share'),
                                  style: AppTheme.getTextStyle(
                                    themeData.textTheme.titleMedium!,
                                    fontWeight: 700,
                                    color: themeData.colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: MySize.size10!),
                            ),
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeData.colorScheme.primary,
                                    elevation: 5),
                                onPressed: () {
                                  _printInvoice = true;
                                  if (pendingAmount >= 0.01) {
                                    alertPending(context);
                                  } else {
                                    if (!saleCreated) {
                                      onSubmit();
                                    }
                                  }
                                },
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('finalize_n_print'),
                                  style: AppTheme.getTextStyle(
                                    themeData.textTheme.titleMedium!,
                                    fontWeight: 700,
                                    color: themeData.colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Card block(
      {Color? backgroundColor, String? subject, amount, Color? textColor}) {
    ThemeData themeData = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MySize.size8!),
      ),
      child: SizedBox(
        height: MySize.size30,
        child: Container(
          padding: EdgeInsets.all(MySize.size2!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                subject!,
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge!,
                    color: themeData.colorScheme.onSurface,
                    fontWeight: 800,
                    muted: true),
              ),
              Text(
                "$symbol $amount",
                overflow: TextOverflow.ellipsis,
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge!,
                    color: textColor, fontWeight: 600, muted: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //calculate multiple payment
  void calculateMultiPayment() {
    totalPaying = 0.0;
    for (var element in payments) {
      totalPaying += element['amount'];
    }
    if (totalPaying > invoiceAmount) {
      changeReturn = totalPaying - invoiceAmount;
      pendingAmount = 0.0;
    } else if (invoiceAmount > totalPaying) {
      pendingAmount = invoiceAmount - totalPaying;
      changeReturn = 0.0;
    } else {
      pendingAmount = 0.0;
      changeReturn = 0.0;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> setPaymentDetails() async {
    List payments =
        await System().get('payment_method', argument!['locationId']);

    final uniquePaymentMethods = <Map<String, dynamic>>[];
    final seenNames = <String>{};

    for (var element in payments) {
      var name = element['name'];
      if (name != null && seenNames.add(name)) {
        uniquePaymentMethods.add({
          'name': element['name'],
          'value': element['label'],
          'account_id': (element['account_id'] != null)
              ? int.parse(element['account_id'].toString())
              : null
        });
      }
    }

    if (mounted) {
      setState(() {
        paymentMethods = uniquePaymentMethods;
      });
    }
  }

  //on submit
  Future<void> onSubmit() async {
    setState(() {
      isLoading = true;
      saleCreated = true;
    });
    //value for sell table
    //TODO: remove change return from here and add it to payments
    Map<String, dynamic> sell = await Sell().createSell(
        invoiceNo: "${USERID}_${DateFormat('yMdHm').format(DateTime.now())}",
        transactionDate: transactionDate,
        changeReturn: changeReturn,
        contactId: argument!['customerId'],
        discountAmount: argument!['discountAmount'],
        discountType: argument!['discountType'],
        invoiceAmount: invoiceAmount,
        locId: argument!['locationId'],
        pending: pendingAmount,
        saleNote: saleNote.text,
        saleStatus: 'final',
        sellId: sellId,
        shippingCharges: (shippingCharges.text != '')
            ? double.parse(shippingCharges.text)
            : 0.00,
        shippingDetails: shippingDetails.text,
        staffNote: staffNote.text,
        taxId: argument!['taxId'],
        serviceStaffId: argument!['serviceStaff'],
        isQuotation: argument!['is_quotation'] ?? 0);

    int? response;
    if (sellId != null) {
      //update sell
      response = sellId;
      await SellDatabase().updateSells(sellId, sell).then((value) async {
        //get payment map
        //TODO: change payment name to payment type.
        //create payment line
        for (var element in payments) {
          if (element['id'] != null) {
            paymentLine = {
              'amount': element['amount'],
              'method': element['method'],
              'note': element['note'],
              'account_id': element['account_id']
            };
            PaymentDatabase()
                .updateEditedPaymentLine(element['id'], paymentLine);
          } else {
            paymentLine = {
              'sell_id': sellId,
              'method': element['method'],
              'amount': element['amount'],
              'note': element['note'],
              'account_id': element['account_id']
            };
            PaymentDatabase().store(paymentLine);
          }
        }
        if (deletedPaymentId.isNotEmpty) {
          PaymentDatabase().deletePaymentLineByIds(deletedPaymentId);
        }
        //check internet connection and create api sell
        if (await Helper().checkConnectivity()) {
          await Sell()
              .createApiSell(sellId: sellId)
              .then((value) => printOption(response));
        } else {
          //print option
          printOption(response);
        }
      });
    } else {
      //save sell in database
      response = await SellDatabase().storeSell(sell);
      //save payments in sell_payments
      Sell().makePayment(payments, response);
      SellDatabase().updateSellLine({'sell_id': response, 'is_completed': 1});
      if (await Helper().checkConnectivity()) {
        await Sell().createApiSell(sellId: response);
      }
      //print option
      printOption(response);
    }
  }

  //print option
  Future<void> printOption(sellId) async {
    Timer(Duration(seconds: 2), () async {
      List sellDetail = await SellDatabase().getSellBySellId(sellId);
      String? invoice = sellDetail[0]['invoice_url'];
      String invoiceNo = sellDetail[0]['invoice_no'];
      //print invoice
      if (_printInvoice) {
        if (printWebInvoice && invoice != null) {
          final response = await http.Client().get(Uri.parse(invoice));
          if (response.statusCode == 200) {
            await Helper()
                .printDocument(sellId, argument!['taxId'], context,
                    invoice: response.body)
                .then((value) {
              Navigator.popUntil(
                  context, ModalRoute.withName('/home'));
            });
          } else {
            await Helper()
                .printDocument(sellId, argument!['taxId'], context)
                .then((value) {
              Navigator.popUntil(
                  context, ModalRoute.withName('/home'));
            });
          }
        } else {
          Helper()
              .printDocument(sellId, argument!['taxId'], context)
              .then((value) {
            Navigator.pushNamedAndRemoveUntil(
                context,
                (argument!['sellId'] == null) ? '/products' : '/sale',
                ModalRoute.withName('/home'));
          });
        }
      } else {
        if (printWebInvoice && invoice != null) {
          final response = await http.Client().get(Uri.parse(invoice));
          if (response.statusCode == 200) {
            await Helper()
                .savePdf(sellId, argument!['taxId'], context, invoiceNo,
                    invoice: response.body)
                .then((value) {
              Navigator.popUntil(
                  context, ModalRoute.withName('/home'));
            });
          } else {
            await Helper()
                .savePdf(sellId, argument!['taxId'], context, invoiceNo)
                .then((value) {
              Navigator.popUntil(
                  context, ModalRoute.withName('/home'));
            });
          }
        } else {
          Helper()
              .savePdf(sellId, argument!['taxId'], context, invoiceNo)
              .then((value) {
            Navigator.pushNamedAndRemoveUntil(
                context,
                (argument!['sellId'] == null) ? '/products' : '/sale',
                ModalRoute.withName('/home'));
          });
        }
      }
    });
  }

  //alert dialog for amount pending
  void alertPending(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Text(AppLocalizations.of(context).translate('pending_message'),
          style: AppTheme.getTextStyle(themeData.textTheme.bodyMedium!,
              color: themeData.colorScheme.onSurface,
              fontWeight: 500,
              muted: true)),
      actions: <Widget>[
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.onPrimary,
                backgroundColor: themeData.colorScheme.primary),
            onPressed: () {
              Navigator.pop(context);
              if (!saleCreated) {
                onSubmit();
              }
            },
            child: Text(AppLocalizations.of(context).translate('ok'))),
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.primary,
                backgroundColor: themeData.colorScheme.onPrimary),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('cancel')))
      ],
    );
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  //alert dialog for confirmation
  void alertConfirm(BuildContext context, index) {
    AlertDialog alert = AlertDialog(
      title: Icon(
        MdiIcons.alert,
        color: Colors.red,
        size: MySize.size50,
      ),
      content: Text(AppLocalizations.of(context).translate('are_you_sure'),
          textAlign: TextAlign.center,
          style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge!,
              color: themeData.colorScheme.onSurface,
              fontWeight: 600,
              muted: true)),
      actions: <Widget>[
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.primary,
                backgroundColor: themeData.colorScheme.onPrimary),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('cancel'))),
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.onError,
                backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              if (sellId != null && payments[index]['id'] != null) {
                deletedPaymentId.add(payments[index]['id']);
              }
              payments.removeAt(index);
              calculateMultiPayment();
            },
            child: Text(AppLocalizations.of(context).translate('ok')))
      ],
    );
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget _buildShippingSection() {
    return Padding(
      padding: EdgeInsets.all(MySize.size8!),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('shipping'),
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.titleMedium!,
                    fontWeight: 700,
                  ),
                ),
                SizedBox(height: MySize.size8),
                Text(
                  "${AppLocalizations.of(context).translate('shipping_charges')}: ${shippingCharges.text}",
                ),
                Text(
                  "${AppLocalizations.of(context).translate('shipping_details')}: ${shippingDetails.text}",
                ),
                if (shippingAddress != null && shippingAddress!.isNotEmpty)
                  Text(
                    "${AppLocalizations.of(context).translate('shipping_address')}: $shippingAddress",
                  ),
                if (shippingStatus != null && shippingStatus!.isNotEmpty)
                  Text(
                    "${AppLocalizations.of(context).translate('shipping_status')}: $shippingStatus",
                  ),
                if (deliveredTo != null && deliveredTo!.isNotEmpty)
                  Text(
                    "${AppLocalizations.of(context).translate('delivered_to')}: $deliveredTo",
                  ),
                if (deliveryPerson != null && deliveryPerson!.isNotEmpty)
                  Text(
                    "${AppLocalizations.of(context).translate('delivery_person')}: $deliveryPerson",
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showShippingModal,
          ),
        ],
      ),
    );
  }

  void _showShippingModal() async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShippingModal(
          shippingDetails: shippingDetails.text,
          shippingAddress: shippingAddress,
          shippingCharges: shippingCharges.text,
          shippingStatus: shippingStatus,
          deliveredTo: deliveredTo,
          deliveryPerson: deliveryPerson,
        );
      },
    );

    if (result != null) {
      setState(() {
        shippingDetails.text = result['shippingDetails'];
        shippingAddress = result['shippingAddress'];
        shippingCharges.text = result['shippingCharges'];
        shippingStatus = result['shippingStatus'];
        deliveredTo = result['deliveredTo'];
        deliveryPerson = result['deliveryPerson'];

        // Recalculate total amount
        invoiceAmount = argument!['invoiceAmount'] +
            (double.tryParse(shippingCharges.text) ?? 0.0);
        calculateMultiPayment();
      });
    }
  }
}
