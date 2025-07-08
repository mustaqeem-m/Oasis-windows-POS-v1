import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../helpers/SizeConfig.dart';
import '../../helpers/otherHelpers.dart';
import '../../locale/MyLocalizations.dart';

class Statistics extends StatelessWidget {
  final int? totalSales;
  final double totalSalesAmount;
  final double totalReceivedAmount;
  final double totalDueAmount;
  final String businessSymbol;

  const Statistics({
    super.key,
    required this.totalSales,
    required this.totalSalesAmount,
    required this.totalReceivedAmount,
    required this.totalDueAmount,
    required this.businessSymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: MySize.size16!),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _infoCard(
              context,
              icon: MdiIcons.chartLine,
              amount: Helper().formatQuantity(totalSales ?? 0),
              subject:
                  AppLocalizations.of(context).translate('number_of_sales'),
              color: const Color(0xff00c6ff),
            ),
          ),
          SizedBox(width: MySize.size16!),
          Expanded(
            child: _infoCard(
              context,
              icon: MdiIcons.cashMultiple,
              amount:
                  '$businessSymbol ${Helper().formatCurrency(totalSalesAmount)}',
              subject: AppLocalizations.of(context).translate('sales_amount'),
              color: const Color(0xffF85032),
            ),
          ),
          SizedBox(width: MySize.size16!),
          Expanded(
            child: _infoCard(
              context,
              icon: MdiIcons.cashCheck,
              amount:
                  '$businessSymbol ${Helper().formatCurrency(totalReceivedAmount)}',
              subject: AppLocalizations.of(context).translate('paid_amount'),
              color: const Color(0xff11998e),
            ),
          ),
          SizedBox(width: MySize.size16!),
          Expanded(
            child: _infoCard(
              context,
              icon: MdiIcons.cashRemove,
              amount: '$businessSymbol ${Helper().formatCurrency(totalDueAmount)}',
              subject: AppLocalizations.of(context).translate('due_amount'),
              color: const Color(0xfff7971e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, 
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
}
