import 'package:flutter/material.dart';

import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../locale/MyLocalizations.dart';

Widget posBottomBar(int page, BuildContext context, Function(int) onTapped) {
  ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  return Material(
    elevation: 0,
    child: Container(
      color: themeData.colorScheme.onPrimary,
      height: MySize.size56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _bottomBarMenu(
            context,
            AppLocalizations.of(context).translate('home'),
            page == 0,
            Icons.home,
            () => onTapped(0),
          ),
          _bottomBarMenu(
            context,
            AppLocalizations.of(context).translate('products'),
            page == 1,
            Icons.shop_two,
            () => onTapped(1),
          ),
          _bottomBarMenu(
            context,
            AppLocalizations.of(context).translate('sales'),
            page == 2,
            Icons.list,
            () => onTapped(2),
          ),
        ],
      ),
    ),
  );
}

Widget _bottomBarMenu(
    BuildContext context, String name, bool isSelected, IconData icon, VoidCallback onPressed) {
  return TextButton(
    onPressed: onPressed,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.white,
        ),
        Text(
          name,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.white,
          ),
        )
      ],
    ),
  );
}

Widget cartBottomBar(route, name, context, [nextArguments]) {
  ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  //TODO: add some shadows.
  return Material(
    child: Container(
      color: themeData.colorScheme.onPrimary,
      height: 55,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _bottomBarMenu(context, name, true, Icons.arrow_forward, () {
            Navigator.pushNamed(context, route, arguments: nextArguments);
          }),
        ],
      ),
    ),
  );
}

//syncAlert
syncing(time, context) {
  AlertDialog alert = AlertDialog(
    content: Row(
      children: [
        CircularProgressIndicator(),
        Container(
            margin: EdgeInsets.only(left: 5),
            child: Text("Sync in progress...")),
      ],
    ),
  );
  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      Future.delayed(Duration(seconds: time), () {
        Navigator.of(context).pop(true);
      });
      return alert;
    },
  );
}
