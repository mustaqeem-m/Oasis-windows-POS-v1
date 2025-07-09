import 'package:flutter/material.dart';
import '../../helpers/AppTheme.dart';
import '../../helpers/SizeConfig.dart';

Widget buildCardHeader(String title, ThemeData themeData) {
  return Container(
    padding: EdgeInsets.symmetric(
        vertical: MySize.size8!, horizontal: MySize.size12!),
    decoration: BoxDecoration(
      color: themeData.colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(MySize.size8!),
    ),
    child: Text(
      title,
      style: AppTheme.getTextStyle(themeData.textTheme.titleMedium,
          fontWeight: 700, color: themeData.colorScheme.primary),
    ),
  );
}
