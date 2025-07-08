import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/SizeConfig.dart';
import '../../helpers/otherHelpers.dart';
import '../../locale/MyLocalizations.dart';

class PaymentDetails extends StatelessWidget {
  final List<Map> method;
  final String businessSymbol;

  const PaymentDetails({
    super.key,
    required this.method,
    required this.businessSymbol,
  });

  @override
  Widget build(BuildContext context) {
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
}
