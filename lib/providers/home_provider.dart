import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_2/models/contact_model.dart';
import 'package:pos_2/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import '../../helpers/otherHelpers.dart';

import '../../models/attendance.dart';
import '../../models/paymentDatabase.dart';
import '../../models/sell.dart';
import '../../models/sellDatabase.dart';
import '../../models/system.dart';
import '../../models/variations.dart';

class HomeProvider with ChangeNotifier {
  bool _isDisposed = false;
  Map<String, dynamic>? user;
  var note = TextEditingController();
  var clockInTime = DateTime.now();
  String? selectedLanguage;
  LatLng? currentLoc;

  String businessSymbol = '';
  String businessLogo = '';
  String defaultImage = 'assets/images/default_product.png';
  String businessName = '';
  String userName = '';

  double totalSalesAmount = 0.00;
  double totalReceivedAmount = 0.00;
  double totalDueAmount = 0.00;
  double byCash = 0.00;
  double byCard = 0.00;
  double byCheque = 0.00;
  double byBankTransfer = 0.00;
  double byOther = 0.00;
  double byCustomPayment_1 = 0.00;
  double byCustomPayment_2 = 0.00;
  double byCustomPayment_3 = 0.00;

  bool accessExpenses = false;
  bool attendancePermission = false;
  bool notPermitted = false;
  bool syncPressed = false;
  bool? checkedIn;

  Map<String, dynamic>? paymentMethods;
  int? totalSales;
  List<Map> method = [], payments = [];

  Map<String, dynamic> _selectedCustomer = {
    'id': 0,
    'name': 'Walk-In Customer',
    'mobile': ''
  };
  Map<String, dynamic> get selectedCustomer => _selectedCustomer;

  Map<String, bool> _dropdownVisibilities = {
    'showCommissionAgent': true,
    'showTypesOfService': true,
    'showTable': true,
    'showServiceStaff': true,
    'showPrinter': true,
  };
  Map<String, bool> get dropdownVisibilities => _dropdownVisibilities;

  HomeProvider() {
    getPermission();
    homepageData();
    Helper().syncCallLogs();
    _initializeCustomer();
    _loadDropdownVisibilities();
  }

  Future<void> _loadDropdownVisibilities() async {
    final prefs = await SharedPreferences.getInstance();
    _dropdownVisibilities = {
      'showCommissionAgent': prefs.getBool('showCommissionAgent') ?? true,
      'showTypesOfService': prefs.getBool('showTypesOfService') ?? true,
      'showTable': prefs.getBool('showTable') ?? true,
      'showServiceStaff': prefs.getBool('showServiceStaff') ?? true,
      'showPrinter': prefs.getBool('showPrinter') ?? true,
    };
    notifyListeners();
  }

  Future<void> updateDropdownVisibility(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
    _dropdownVisibilities[key] = value;
    notifyListeners();
  }

  void _initializeCustomer() async {
    List customers = await Contact().get();
    for (var value in customers) {
      if (value['name'] == 'Walk-In Customer') {
        _selectedCustomer = {
          'id': value['id'],
          'name': value['name'],
          'mobile': value['mobile']
        };
        notifyListeners();
        break;
      }
    }
  }

  void updateSelectedCustomer(Map<String, dynamic> customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void resetCustomer() {
    _initializeCustomer();
  }

  Future<void> homepageData() async {
    var prefs = await SharedPreferences.getInstance();
    user = await System().get('loggedInUser');
    userName = "${user?['surname'] ?? ''} ${user?['first_name'] ?? ''}";
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
    if (!_isDisposed) {
      notifyListeners();
    }
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
        if (!_isDisposed) {
          notifyListeners();
        }
      } else {
        checkedIn = null;
        if (!_isDisposed) {
          notifyListeners();
        }
      }
    } else {
      checkedIn = null;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> sync(BuildContext context) async {
    if (!syncPressed) {
      syncPressed = true;
      if (!_isDisposed) {
        notifyListeners();
      }
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
                    child: Text('Sync in progress...',
                        style: TextStyle(color: Colors.white))),
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
      syncPressed = false;
      if (!_isDisposed) {
        notifyListeners();
      }
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
        attendancePermission = true;
      } else {
        checkedIn = null;
      }
    });

    if (await Helper().getPermission('all_expense.access') ||
        await Helper().getPermission('view_own_expense')) {
      accessExpenses = true;
    }
    if (!_isDisposed) {
      notifyListeners();
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
      totalSalesAmount = (totalSalesAmount + (sell['invoice_amount'] ?? 0.0));
      totalReceivedAmount = (totalReceivedAmount + (paidAmount - returnAmount));
      totalDueAmount = (totalDueAmount + (sell['pending_amount'] ?? 0.0));
    }
    if (!_isDisposed) {
      notifyListeners();
    }
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
          if (byCash > 0 && row['key'] == 'cash') {
            method.add({'key': row['value'], 'value': byCash});
          }
          if (byCard > 0 && row['key'] == 'card') {
            method.add({'key': row['value'], 'value': byCard});
          }
          if (byCheque > 0 && row['key'] == 'cheque') {
            method.add({'key': row['value'], 'value': byCheque});
          }
          if (byBankTransfer > 0 && row['key'] == 'bank_transfer') {
            method.add({'key': row['value'], 'value': byBankTransfer});
          }
          if (byOther > 0 && row['key'] == 'other') {
            method.add({'key': row['value'], 'value': byOther});
          }
          if (byCustomPayment_1 > 0 && row['key'] == 'custom_pay_1') {
            method.add({'key': row['value'], 'value': byCustomPayment_1});
          }
          if (byCustomPayment_2 > 0 && row['key'] == 'custom_pay_2') {
            method.add({'key': row['value'], 'value': byCustomPayment_2});
          }
          if (byCustomPayment_3 > 0 && row['key'] == 'custom_pay_3') {
            method.add({'key': row['value'], 'value': byCustomPayment_3});
          }
        }
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    });
  }

  void updateLanguage(String? newLanguage) {
    selectedLanguage = newLanguage;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void onCheckInOut(bool newCheckedIn) async {
    checkedIn = newCheckedIn;
    await Attendance().getCheckInTime(USERID).then((value) {
      if (value != null) {
        clockInTime = DateTime.parse(value);
      }
    });
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
