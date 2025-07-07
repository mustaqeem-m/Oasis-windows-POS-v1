import 'package:app_settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:pos_2/helpers/toast_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/attendance.dart';
import '../models/paymentDatabase.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';
import '../pages/login.dart';
import 'elements.dart';

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
        drawer: homePageDrawer(),
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
                    '${AppLocalizations.of(context).translate('welcome')} $userName',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
              statistics(),
              checkIO(),
              paymentDetails(),
            ],
          ),
        ),
        bottomNavigationBar: posBottomBar('home', context));
  }

  Widget homePageDrawer() {
    return Drawer(
      child: Container(
        color: Theme.of(context).drawerTheme.backgroundColor,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: MySize.scaleFactorHeight! * 250,
              child: DrawerHeader(
                decoration:
                    BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: CachedNetworkImage(
                    fit: BoxFit.fill,
                    errorWidget: (context, url, error) =>
                        Image.asset(defaultImage),
                    placeholder: (context, url) => Image.asset(defaultImage),
                    imageUrl: businessLogo),
              ),
            ),
            Expanded(
              flex: 9,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Visibility(
                    visible: (notPermitted),
                    child: GestureDetector(
                      onTap: () {
                        AppSettings.openAppSettings();
                      },
                      child: Text(
                        "Allow permissions",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: changeAppLanguage(),
                  ),
                  Visibility(
                    visible: accessExpenses,
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.googleSpreadsheet,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onTap: () async {
                        if (await Helper().checkConnectivity()) {
                          Navigator.pushNamed(context, '/expense');
                        } else {
                          ToastHelper.show(
                              context,
                              AppLocalizations.of(context)
                                  .translate('check_connectivity'));
                        }
                      },
                      title: Text(
                        AppLocalizations.of(context).translate('expenses'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.cardAccountDetailsOutline,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('contact_payment'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/contactPayment');
                      } else {
                        ToastHelper.show(
                            context,
                            AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.faceAgent,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('follow_ups'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/followUp');
                      } else {
                        ToastHelper.show(
                            context,
                            AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  Visibility(
                    visible: Config().showFieldForce,
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.humanMale,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onTap: () async {
                        if (await Helper().checkConnectivity()) {
                          Navigator.pushNamed(context, '/fieldForce');
                        } else {
                          ToastHelper.show(
                              context,
                              AppLocalizations.of(context)
                                  .translate('check_connectivity'));
                        }
                      },
                      title: Text(
                        AppLocalizations.of(context)
                            .translate('field_force_visits'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.contact_phone_outlined,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('contacts'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/leads');
                      } else {
                        ToastHelper.show(
                            context,
                            AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.local_shipping_outlined,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('shipment'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/shipment');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.syncIcon,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).cardColor,
                              content: Row(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary),
                                  ),
                                  Container(
                                      margin: const EdgeInsets.only(left: 15),
                                      child: Text(
                                          AppLocalizations.of(context)
                                              .translate('loading_data'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface))),
                                ],
                              ),
                            );
                          },
                        );
                        await Variations().refresh();
                        System().refresh().then((value) {
                          Navigator.popUntil(
                              context, ModalRoute.withName('/home'));
                        });
                      } else {
                        ToastHelper.show(
                            context,
                            AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                    title: Text(
                      AppLocalizations.of(context).translate('refresh'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                flex: 1,
                child: Container(
                    alignment: Alignment.bottomCenter,
                    margin: const EdgeInsets.all(10),
                    child: Text(
                      "${Config().copyright}  ${Config().appName}  ${Config().version}",
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontWeight: FontWeight.normal),
                    )))
          ],
        ),
      ),
    );
  }

  Widget changeAppLanguage() {
    return ChangeNotifierProvider(
      create: (context) => AppLanguage(),
      child: Consumer<AppLanguage>(
        builder: (context, appLanguage, child) {
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Theme.of(context).cardColor,
              onChanged: (String? newValue) {
                final selectedLangMap = Config().lang.firstWhere(
                      (element) => element['languageCode'] == newValue,
                      orElse: () => {
                        'languageCode': 'en',
                        'countryCode': 'US'
                      }, // Fallback to English if not found
                    );
                appLanguage.changeLanguage(Locale(
                    selectedLangMap['languageCode']!,
                    selectedLangMap['countryCode']));
                setState(() {
                  selectedLanguage = newValue;
                });
                Navigator.pushReplacementNamed(context, '/splash');
              },
              value: selectedLanguage,
              items: Config().lang.map<DropdownMenuItem<String>>((Map locale) {
                return DropdownMenuItem<String>(
                  value: locale['languageCode'],
                  child: Text(
                    locale['name'],
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
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

  Widget infoCard(
      {required IconData icon,
      required String subject,
      required String amount,
      required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(MySize.size16!),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(subject,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(amount,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget statistics() {
    if (totalSales.toString() == 'null') {
      totalSales = 0;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: MySize.size16!),
      child: Row(
        children: <Widget>[
          Expanded(
            child: infoCard(
              icon: MdiIcons.chartLine,
              amount: Helper().formatQuantity(totalSales),
              subject:
                  AppLocalizations.of(context).translate('number_of_sales'),
              color: const Color(0xff00c6ff),
            ),
          ),
          SizedBox(width: MySize.size16!),
          Expanded(
            child: infoCard(
              icon: MdiIcons.cashMultiple,
              amount:
                  '$businessSymbol ${Helper().formatCurrency(totalSalesAmount)}',
              subject: AppLocalizations.of(context).translate('sales_amount'),
              color: const Color(0xffF85032),
            ),
          ),
          SizedBox(width: MySize.size16!),
          Expanded(
            child: infoCard(
              icon: MdiIcons.cashCheck,
              amount:
                  '$businessSymbol ${Helper().formatCurrency(totalReceivedAmount)}',
              subject: AppLocalizations.of(context).translate('paid_amount'),
              color: const Color(0xff11998e),
            ),
          ),
          SizedBox(width: MySize.size16!),
          Expanded(
            child: infoCard(
              icon: MdiIcons.cashRemove,
              amount:
                  '$businessSymbol ${Helper().formatCurrency(totalDueAmount)}',
              subject: AppLocalizations.of(context).translate('due_amount'),
              color: const Color(0xfff7971e),
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentDetails() {
    return Container(
      padding: EdgeInsets.all(MySize.size16!),
      margin: EdgeInsets.all(MySize.size16!),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.all(Radius.circular(MySize.size12!)),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 1),
      ),
      child: Column(
        children: <Widget>[
          Text(AppLocalizations.of(context).translate('payment_details'),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              itemCount: method.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(method[index]['key'],
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14)),
                      Text(
                          '$businessSymbol ${Helper().formatCurrency(method[index]['value'])}',
                          style: GoogleFonts.robotoMono(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                );
              })
        ],
      ),
    );
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

  Widget checkIO() {
    if (checkedIn != null) {
      return Padding(
        padding: EdgeInsets.only(top: MySize.size20!),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: (!checkedIn!)
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () async {
                Helper().syncCallLogs();
                showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        title: Text(
                            (!checkedIn!)
                                ? AppLocalizations.of(context)
                                    .translate('check_in_note')
                                : AppLocalizations.of(context)
                                    .translate('check_out_note'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold)),
                        content: TextFormField(
                            controller: note,
                            autofocus: true,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (await Helper().checkConnectivity()) {
                                try {
                                  await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.high)
                                      .then((Position position) {});
                                } catch (e) {}
                                if (checkedIn == false) {
                                  var ipAddress =
                                      IpAddress(type: RequestType.json);
                                  dynamic data = await ipAddress.getIpAddress();
                                  String iP = data.toString();

                                  try {
                                    await Geolocator.getCurrentPosition(
                                            desiredAccuracy:
                                                LocationAccuracy.high)
                                        .then((Position position) {
                                      currentLoc = LatLng(position.latitude,
                                          position.longitude);
                                    });
                                  } catch (e) {}

                                  var checkInMap = await Attendance().doCheckIn(
                                      checkInNote: note.text,
                                      iPAddress: iP,
                                      latitude: (currentLoc != null)
                                          ? currentLoc!.latitude
                                          : '',
                                      longitude: (currentLoc != null)
                                          ? currentLoc!.longitude
                                          : '');
                                  ToastHelper.show(context, checkInMap);
                                  note.clear();
                                } else {
                                  try {
                                    await Geolocator.getCurrentPosition(
                                            desiredAccuracy:
                                                LocationAccuracy.high)
                                        .then((Position position) {
                                      currentLoc = LatLng(position.latitude,
                                          position.longitude);
                                    });
                                  } catch (e) {}

                                  var checkOutMap = await Attendance()
                                      .doCheckOut(
                                          latitude: (currentLoc != null)
                                              ? currentLoc!.latitude
                                              : '',
                                          longitude: (currentLoc != null)
                                              ? currentLoc!.longitude
                                              : '',
                                          checkOutNote: note.text);
                                  ToastHelper.show(context, checkOutMap);
                                  note.clear();
                                }
                                checkedIn = await Attendance()
                                    .getAttendanceStatus(USERID);
                                await Attendance()
                                    .getCheckInTime(USERID)
                                    .then((value) {
                                  if (value != null) {
                                    clockInTime = DateTime.parse(value);
                                  }
                                });
                                setState(() {});
                              } else
                                ToastHelper.show(
                                    context,
                                    AppLocalizations.of(context)
                                        .translate('check_connectivity'));
                            },
                            child: Text(
                                AppLocalizations.of(context).translate('ok'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                                AppLocalizations.of(context)
                                    .translate('cancel'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                          )
                        ],
                      );
                    });
              },
              child: Text(
                  (!checkedIn!)
                      ? AppLocalizations.of(context).translate('check_in')
                      : AppLocalizations.of(context).translate('check_out'),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: (!checkedIn!)
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            const SizedBox(height: 10),
            Text(
                (!checkedIn!)
                    ? ''
                    : DateTime.now().difference(clockInTime).toString(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    )),
          ],
        ),
      );
    } else
      return Container();
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
