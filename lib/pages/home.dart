import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_2/pages/elements.dart';
import 'package:pos_2/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/home/check_io.dart';
import '../../components/home/home_drawer.dart';
import '../../components/home/payment_details.dart';
import '../../components/home/statistics.dart';
import '../../config.dart';
import '../../helpers/AppTheme.dart';
import '../../helpers/SizeConfig.dart';
import '../../helpers/otherHelpers.dart';
import '../../helpers/toast_helper.dart';
import '../../locale/MyLocalizations.dart';
import '../../models/attendance.dart';
import '../../models/paymentDatabase.dart';
import '../../models/sell.dart';
import '../../models/sellDatabase.dart';
import '../../models/system.dart';
import '../../models/variations.dart';
// import '../elements.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var user,
      note = TextEditingController(),
      clockInTime = DateTime.now(),
      selectedLanguage;
  LatLng? currentLoc;

  String businessSymbol = '',
      businessLogo = '',
      defaultImage = 'assets/images/default_product.png',
      businessName = '',
      userName = '';

  double totalSalesAmount = 0.00,
      totalReceivedAmount = 0.00,
      totalDueAmount = 0.00,
      byCash = 0.00,
      byCard = 0.00,
      byCheque = 0.00,
      byBankTransfer = 0.00,
      byOther = 0.00,
      byCustomPayment_1 = 0.00,
      byCustomPayment_2 = 0.00,
      byCustomPayment_3 = 0.00;

  bool accessExpenses = false,
      attendancePermission = false,
      notPermitted = false,
      syncPressed = false;
  bool? checkedIn;

  Map<String, dynamic>? paymentMethods;
  int? totalSales;
  List<Map> method = [], payments = [];

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    getPermission();
    homepageData();
    Helper().syncCallLogs();
  }

  Future<void> homepageData() async {
    var prefs = await SharedPreferences.getInstance();
    user = await System().get('loggedInUser');
    userName = ((user['surname'] != null) ? user['surname'] : "") +
        ' ' +
        user['first_name'];
    await loadPaymentDetails();
    await Helper().getFormattedBusinessDetails().then((value) {
      businessSymbol = value['symbol'];
      businessLogo = value['logo'] ?? Config().defaultBusinessImage;
      businessName = value['name'];
      Config.quantityPrecision = value['quantityPrecision'] ?? 2;
      Config.currencyPrecision = value['currencyPrecision'] ?? 2;
    });
    selectedLanguage =
        prefs.getString('language_code') ?? Config().defaultLanguage;
    setState(() {});
  }

  Future<void> checkIOButtonDisplay() async {
    await Attendance().getCheckInTime(USERID).then((value) {
      if (value != null) {
        clockInTime = DateTime.parse(value);
      }
    });
    var activeSubscriptionDetails = await System().get('active-subscription');
    if (activeSubscriptionDetails.length > 0 &&
        activeSubscriptionDetails[0].containsKey('package_details')) {
      Map<String, dynamic> packageDetails =
          activeSubscriptionDetails[0]['package_details'];
      if (packageDetails.containsKey('essentials_module') &&
          packageDetails['essentials_module'].toString() == '1') {
        checkedIn = await Attendance().getAttendanceStatus(USERID);
        setState(() {});
      } else {
        setState(() {
          checkedIn = null;
        });
      }
    } else {
      setState(() {
        checkedIn = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: HomePageDrawer(
          businessLogo: businessLogo,
          defaultImage: defaultImage,
          notPermitted: notPermitted,
          accessExpenses: accessExpenses,
          selectedLanguage: selectedLanguage ?? 'en',
          onLanguageChanged: (newValue) {
            setState(() {
              selectedLanguage = newValue;
            });
          },
        ),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text(AppLocalizations.of(context).translate('home'),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold)),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                (await Helper().checkConnectivity())
                    ? await sync()
                    : ToastHelper.show(
                        context,
                        AppLocalizations.of(context)
                            .translate('check_connectivity'));
              },
              child: Text(
                AppLocalizations.of(context).translate('sync'),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await SellDatabase().getNotSyncedSells().then((value) {
                  if (value.isEmpty) {
                    prefs.setInt('prevUserId', USERID!);
                    prefs.remove('userId');
                    Navigator.pushReplacementNamed(context, '/login');
                  } else {
                    ToastHelper.show(
                        context,
                        AppLocalizations.of(context)
                            .translate('sync_all_sales_before_logout'));
                  }
                });
              },
              child: Text(
                AppLocalizations.of(context).translate('logout'),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(MySize.size16!),
                child: Text(
                    '${AppLocalizations.of(context).translate('welcome')} ${userName ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
              Statistics(
                totalSales: totalSales,
                totalSalesAmount: totalSalesAmount,
                totalReceivedAmount: totalReceivedAmount,
                totalDueAmount: totalDueAmount,
                businessSymbol: businessSymbol,
              ),
              CheckIO(
                checkedIn: checkedIn,
                clockInTime: clockInTime,
                onCheckInOut: (newCheckedIn) async {
                  setState(() {
                    checkedIn = newCheckedIn;
                  });
                  await Attendance().getCheckInTime(USERID).then((value) {
                    if (value != null) {
                      setState(() {
                        clockInTime = DateTime.parse(value);
                      });
                    }
                  });
                },
              ),
              PaymentDetails(
                method: method,
                businessSymbol: businessSymbol,
              ),
            ],
          ),
        ),
        bottomNavigationBar: posBottomBar('home', context));
  }

  Future<void> sync() async {
    if (!syncPressed) {
      syncPressed = true;
      showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xff112240),
            content: Row(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff64ffda)),
                ),
                Container(
                    margin: const EdgeInsets.only(left: 15),
                    child: Text(
                        AppLocalizations.of(context)
                            .translate('sync_in_progress'),
                        style: GoogleFonts.orbitron(color: Colors.white))),
              ],
            ),
          );
        },
      );
      await Sell().createApiSell(syncAll: true).then((value) async {
        await Variations().refresh().then((value) {
          Navigator.pop(context);
        });
      });
    }
  }

  Future<void> getPermission() async {
    List<PermissionStatus> status = [
      await Permission.location.status,
      await Permission.storage.status,
      await Permission.camera.status,
    ];
    notPermitted = status.contains(PermissionStatus.denied);
    await Helper()
        .getPermission('essentials.allow_users_for_attendance_from_api')
        .then((value) {
      if (value == true) {
        checkIOButtonDisplay();
        setState(() {
          attendancePermission = true;
        });
      } else {
        setState(() {
          checkedIn = null;
        });
      }
    });

    if (await Helper().getPermission('all_expense.access') ||
        await Helper().getPermission('view_own_expense')) {
      setState(() {
        accessExpenses = true;
      });
    }
  }

  Future<List> loadStatistics() async {
    List result = await SellDatabase().getSells();
    totalSales = result.length;
    for (var sell in result) {
      List payment = await PaymentDatabase().get(sell['id'], allColumns: true);
      var paidAmount = 0.0;
      var returnAmount = 0.0;
      for (var element in payment) {
        if (element['is_return'] == 0) {
          paidAmount += element['amount'];
          payments.add({'key': element['method'], 'value': element['amount']});
        } else {
          returnAmount += element['amount'];
        }
      }
      totalSalesAmount = (totalSalesAmount + sell['invoice_amount']);
      totalReceivedAmount = (totalReceivedAmount + (paidAmount - returnAmount));
      totalDueAmount = (totalDueAmount + sell['pending_amount']);
    }
    setState(() {});
    return result;
  }

  Future<void> loadPaymentDetails() async {
    var paymentMethod = [];
    await System().get('payment_methods').then((value) {
      value.forEach((element) {
        element.forEach((k, v) {
          paymentMethod.add({'key': '$k', 'value': '$v'});
        });
      });
    });

    await loadStatistics().then((value) {
      Future.delayed(const Duration(seconds: 1), () {
        for (var row in payments) {
          if (row['key'] == 'cash') {
            byCash += row['value'];
          }

          if (row['key'] == 'card') {
            byCard += row['value'];
          }

          if (row['key'] == 'cheque') {
            byCheque += row['value'];
          }

          if (row['key'] == 'bank_transfer') {
            byBankTransfer += row['value'];
          }

          if (row['key'] == 'other') {
            byOther += row['value'];
          }

          if (row['key'] == 'custom_pay_1') {
            byCustomPayment_1 += row['value'];
          }

          if (row['key'] == 'custom_pay_2') {
            byCustomPayment_2 += row['value'];
          }
          if (row['key'] == 'custom_pay_3') {
            byCustomPayment_3 += row['value'];
          }
        }
        for (var row in paymentMethod) {
          if (byCash > 0 && row['key'] == 'cash')
            method.add({'key': row['value'], 'value': byCash});
          if (byCard > 0 && row['key'] == 'card')
            method.add({'key': row['value'], 'value': byCard});
          if (byCheque > 0 && row['key'] == 'cheque')
            method.add({'key': row['value'], 'value': byCheque});
          if (byBankTransfer > 0 && row['key'] == 'bank_transfer')
            method.add({'key': row['value'], 'value': byBankTransfer});
          if (byOther > 0 && row['key'] == 'other')
            method.add({'key': row['value'], 'value': byOther});
          if (byCustomPayment_1 > 0 && row['key'] == 'custom_pay_1')
            method.add({'key': row['value'], 'value': byCustomPayment_1});
          if (byCustomPayment_2 > 0 && row['key'] == 'custom_pay_2')
            method.add({'key': row['value'], 'value': byCustomPayment_2});
          if (byCustomPayment_3 > 0 && row['key'] == 'custom_pay_3')
            method.add({'key': row['value'], 'value': byCustomPayment_3});
        }
        if (mounted) {
          setState(() {});
        }
      });
    });
  }
}
