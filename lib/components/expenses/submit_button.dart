import 'package:flutter/material.dart';
import '../../helpers/AppTheme.dart';
import '../../helpers/SizeConfig.dart';
import '../../locale/MyLocalizations.dart';

class SubmitButton extends StatelessWidget {
  final ThemeData themeData;
  final VoidCallback onPressed;

  const SubmitButton({
    super.key,
    required this.themeData,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeData.colorScheme.primary,
          padding: EdgeInsets.symmetric(vertical: MySize.size16!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MySize.size12!),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          AppLocalizations.of(context).translate('submit'),
          style: AppTheme.getTextStyle(themeData.textTheme.titleMedium,
              color: themeData.colorScheme.onSecondary, fontWeight: 700),
        ),
      ),
    );
  }
}
