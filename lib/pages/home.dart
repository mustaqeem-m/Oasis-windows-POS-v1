import 'package:flutter/material.dart';
import 'package:pos_2/pages/cart.dart';
import 'package:pos_2/pages/contacts.dart';
import 'package:pos_2/pages/expenses.dart';
import 'package:pos_2/pages/field_force.dart';
import 'package:pos_2/pages/follow_up.dart';
import 'package:pos_2/pages/login.dart';
import 'package:pos_2/pages/products.dart';
import 'package:pos_2/pages/sales.dart';
import 'package:pos_2/pages/shipment.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/home/check_io.dart';
import '../../components/home/home_drawer.dart';
import '../../components/home/payment_details.dart';
import '../../components/home/statistics.dart';
import '../../helpers/AppTheme.dart';
import '../../helpers/SizeConfig.dart';
import '../../helpers/otherHelpers.dart';
import '../../helpers/toast_helper.dart';
import '../../locale/MyLocalizations.dart';
import '../../models/sellDatabase.dart';
import '../../providers/home_provider.dart';
import 'elements.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    HomePage(),
    Products(),
    Sales(),
  ];

  final List<String> _pageTitles = [
    'home',
    'products',
    'sales',
  ];

  void _onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void _onBottomBarTapped(int page) {
    _pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: HomePageDrawer(
            businessLogo: provider.businessLogo,
            defaultImage: provider.defaultImage,
            notPermitted: provider.notPermitted,
            accessExpenses: provider.accessExpenses,
            selectedLanguage: provider.selectedLanguage ?? 'en',
            onLanguageChanged: (newValue) {
              provider.updateLanguage(newValue);
            },
          ),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            title: Text(AppLocalizations.of(context).translate(_pageTitles[_page]),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold)),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  (await Helper().checkConnectivity())
                      ? await provider.sync(context)
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
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setInt('prevUserId', USERID!);
                  prefs.remove('userId');
                  Navigator.pushReplacementNamed(context, '/login');
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
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _pages,
            physics: const NeverScrollableScrollPhysics(),
          ),
          bottomNavigationBar:
              posBottomBar(_page, context, _onBottomBarTapped),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (context, provider, child) {
      return SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(MySize.size16!),
              child: Text(
                  '${AppLocalizations.of(context).translate('welcome')} ${provider.userName}',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
            Statistics(
              totalSales: provider.totalSales,
              totalSalesAmount: provider.totalSalesAmount,
              totalReceivedAmount: provider.totalReceivedAmount,
              totalDueAmount: provider.totalDueAmount,
              businessSymbol: provider.businessSymbol,
            ),
            CheckIO(
              checkedIn: provider.checkedIn,
              clockInTime: provider.clockInTime,
              onCheckInOut: (newCheckedIn) {
                provider.onCheckInOut(newCheckedIn);
              },
            ),
            PaymentDetails(
              method: provider.method,
              businessSymbol: provider.businessSymbol,
            ),
          ],
        ),
      );
    });
  }
}
