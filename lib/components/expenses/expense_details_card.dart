import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/SizeConfig.dart';
import '../../locale/MyLocalizations.dart';
import 'card_header.dart';

class ExpenseDetailsCard extends StatelessWidget {
  final ThemeData themeData;
  final Map<String, dynamic> selectedExpenseCategoryId;
  final List<Map<String, dynamic>> expenseCategories;
  final Function(Map<String, dynamic>?) onExpenseCategoryChanged;
  final Map<String, dynamic> selectedExpenseSubCategoryId;
  final List<Map<String, dynamic>> expenseSubCategories;
  final Function(Map<String, dynamic>?) onExpenseSubCategoryChanged;
  final TextEditingController expenseAmount;
  final String symbol;
  final TextEditingController expenseNote;

  const ExpenseDetailsCard({
    super.key,
    required this.themeData,
    required this.selectedExpenseCategoryId,
    required this.expenseCategories,
    required this.onExpenseCategoryChanged,
    required this.selectedExpenseSubCategoryId,
    required this.expenseSubCategories,
    required this.onExpenseSubCategoryChanged,
    required this.expenseAmount,
    required this.symbol,
    required this.expenseNote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MySize.size12!)),
      child: Padding(
        padding: EdgeInsets.all(MySize.size16!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCardHeader(
                AppLocalizations.of(context).translate('expense_details'),
                themeData),
            SizedBox(height: MySize.size16!),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedExpenseCategoryId,
              dropdownColor: themeData.colorScheme.surface,
              items: expenseCategories.map((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Text(
                    item['name'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: onExpenseCategoryChanged,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)
                    .translate('expense_categories'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MySize.size8!),
                ),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            SizedBox(height: MySize.size16!),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedExpenseSubCategoryId,
              dropdownColor: themeData.colorScheme.surface,
              items: expenseSubCategories.map((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Text(
                    item['name'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: onExpenseSubCategoryChanged,
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.of(context).translate('sub_categories'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MySize.size8!),
                ),
                prefixIcon: Icon(Icons.subdirectory_arrow_right),
              ),
            ),
            SizedBox(height: MySize.size16!),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)
                      .translate('please_enter_expense_amount');
                }
                return null;
              },
              decoration: InputDecoration(
                prefixText: symbol,
                labelText:
                    AppLocalizations.of(context).translate('expense_amount'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MySize.size8!),
                ),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              controller: expenseAmount,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')),
              ],
              textAlign: TextAlign.start,
            ),
            SizedBox(height: MySize.size16!),
            TextFormField(
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.of(context).translate('expense_note'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MySize.size8!),
                ),
                prefixIcon: Icon(Icons.note),
              ),
              controller: expenseNote,
            ),
          ],
        ),
      ),
    );
  }
}