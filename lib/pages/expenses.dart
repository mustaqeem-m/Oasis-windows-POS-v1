import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_2/helpers/toast_helper.dart';

import '../apis/expenses.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/expenses.dart';
import '../models/system.dart';

class Expense extends StatefulWidget {
  const Expense({super.key});

  @override
  _ExpenseState createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  List<Map<String, dynamic>> expenseCategories = [],
      expenseSubCategories = [],
      paymentMethods = [],
      paymentAccounts = [],
      locationListMap = [],
      taxListMap = [];

  Map<String, dynamic> selectedLocation = {'id': 0, 'name': 'set location'};
  Map<String, dynamic> selectedTax = {'id': 0, 'name': 'Tax rate', 'amount': 0};
  Map<String, dynamic> selectedExpenseCategoryId = {'id': 0, 'name': 'Select'};
  Map<String, dynamic> selectedExpenseSubCategoryId = {
    'id': 0,
    'name': 'Select'
  };
  Map<String, dynamic> selectedPaymentAccount = {'id': null, 'name': "None"};
  Map<String, dynamic> selectedPaymentMethod = {
    'name': 'name',
    'value': 'value',
    'account_id': null
  };

  TextEditingController expenseAmount = TextEditingController(),
      expenseNote = TextEditingController(),
      payingAmount = TextEditingController();

  String symbol = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    Helper().syncCallLogs();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    await setLocationMap();
    await setTaxMap();
    await setExpenseCategories();

    if (selectedLocation['id'] != 0) {
      // Check if a valid location is selected
      await setPaymentDetails(selectedLocation['id']);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    expenseAmount.dispose();
    expenseNote.dispose();
    payingAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(
        themeData.brightness == Brightness.dark
            ? AppTheme.themeDark
            : AppTheme.themeLight);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(AppLocalizations.of(context).translate('expenses'),
            style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                fontWeight: 600)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(MySize.size16!),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildLocationAndTaxSection(themeData),
                    SizedBox(height: MySize.size24!),
                    _buildExpenseDetailsCard(themeData),
                    SizedBox(height: MySize.size24!),
                    _buildPaymentCard(themeData),
                    SizedBox(height: MySize.size24!),
                    _buildSubmitButton(themeData),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocationAndTaxSection(ThemeData themeData) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedLocation,
            dropdownColor: themeData.colorScheme.surface,
            items: locationListMap.map((item) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: item,
                child: Text(item['name'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black)),
              );
            }).toList(),
            onChanged: (item) {
              if (item != null) {
                setState(() {
                  selectedLocation = item;
                  setExpenseCategories();
                  setPaymentDetails(selectedLocation['id']).then((_) {
                    if (paymentMethods.isNotEmpty) {
                      selectedPaymentMethod = paymentMethods[0];
                    } else {
                      selectedPaymentMethod = {
                        'name': 'name',
                        'value': 'value',
                        'account_id': null
                      };
                    }
                    if (paymentAccounts.isNotEmpty) {
                      selectedPaymentAccount = paymentAccounts[0];
                      for (var element in paymentAccounts) {
                        if (selectedPaymentMethod['account_id'] ==
                            element['id']) {
                          selectedPaymentAccount = element;
                        }
                      }
                    } else {
                      selectedPaymentAccount = {'id': null, 'name': "None"};
                    }
                  });
                });
              }
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('location'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MySize.size8!),
              ),
              prefixIcon: Icon(Icons.location_on),
              filled: true,
              fillColor: themeData.colorScheme.surface,
            ),
          ),
        ),
        SizedBox(width: MySize.size16!),
        Expanded(
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedTax,
            dropdownColor: themeData.colorScheme.surface,
            items: taxListMap.map((item) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: item,
                child: Text(
                  item['name'],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (item) {
              if (item != null) {
                setState(() {
                  selectedTax = item;
                });
              }
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('tax'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MySize.size8!),
              ),
              prefixIcon: Icon(Icons.receipt),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseDetailsCard(ThemeData themeData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MySize.size12!)),
      child: Padding(
        padding: EdgeInsets.all(MySize.size16!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
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
              onChanged: (item) {
                if (item != null) {
                  setState(() {
                    selectedExpenseCategoryId = item;
                    expenseSubCategories = [
                      {'id': 0, 'name': 'Select'}
                    ];
                    selectedExpenseSubCategoryId = expenseSubCategories[0];

                    if (item.containsKey('sub_categories') &&
                        item['sub_categories'] is List &&
                        (item['sub_categories'] as List).isNotEmpty) {
                      var subCategoriesData = item['sub_categories'] as List;
                      for (var element in subCategoriesData) {
                        if (element is Map) {
                          expenseSubCategories
                              .add(Map<String, dynamic>.from(element));
                        }
                      }
                    }
                  });
                }
              },
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
              onChanged: (item) {
                if (item != null) {
                  setState(() {
                    selectedExpenseSubCategoryId = item;
                  });
                }
              },
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

  Widget _buildPaymentCard(ThemeData themeData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MySize.size12!)),
      child: Padding(
        padding: EdgeInsets.all(MySize.size16!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
                AppLocalizations.of(context).translate('payment'), themeData),
            SizedBox(height: MySize.size16!),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) value = '0.00';
                if (expenseAmount.text.isEmpty ||
                    double.tryParse(value) == null ||
                    double.parse(value) > double.parse(expenseAmount.text)) {
                  return AppLocalizations.of(context)
                      .translate('enter_valid_payment_amount');
                }
                return null;
              },
              decoration: InputDecoration(
                prefixText: symbol,
                labelText:
                    AppLocalizations.of(context).translate('payment_amount'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MySize.size8!),
                ),
                prefixIcon: Icon(Icons.payment),
              ),
              controller: payingAmount,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')),
              ],
              textAlign: TextAlign.start,
            ),
            SizedBox(height: MySize.size16!),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedPaymentMethod,
              dropdownColor: themeData.colorScheme.surface,
              items: paymentMethods.map((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Text(item['value'],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: (item) {
                if (item != null) {
                  setState(() {
                    selectedPaymentMethod = item;
                    selectedPaymentAccount = paymentAccounts.firstWhere(
                        (element) => element['id'] == item['account_id'],
                        orElse: () => paymentAccounts.isNotEmpty
                            ? paymentAccounts[0]
                            : {'id': null, 'name': "None"});
                  });
                }
              },
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.of(context).translate('payment_method'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MySize.size8!),
                ),
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            SizedBox(height: MySize.size16!),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedPaymentAccount,
              dropdownColor: themeData.colorScheme.surface,
              items: paymentAccounts.map((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Text(
                    item['name'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (item) {
                if (item != null) {
                  setState(() {
                    selectedPaymentAccount = item;
                    selectedPaymentMethod['account_id'] = item['id'];
                  });
                }
              },
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.of(context).translate('payment_account'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MySize.size8!),
                ),
                prefixIcon: Icon(Icons.account_balance),
                filled: true,
                fillColor: themeData.colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(String title, ThemeData themeData) {
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

  Widget _buildSubmitButton(ThemeData themeData) {
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
        onPressed: () async {
          if (await Helper().checkConnectivity()) {
            if (_formKey.currentState!.validate()) {
              onSubmit();
            }
          } else {
            ToastHelper.show(context,
                AppLocalizations.of(context).translate('check_connectivity'));
          }
        },
        child: Text(
          AppLocalizations.of(context).translate('submit'),
          style: AppTheme.getTextStyle(themeData.textTheme.titleMedium,
              color: themeData.colorScheme.onSecondary, fontWeight: 700),
        ),
      ),
    );
  }

  Future<void> setLocationMap() async {
    var locations = await System().get('location');
    var newLocationList = <Map<String, dynamic>>[];
    if (locations is List) {
      for (var loc in locations) {
        if (loc is Map) {
          newLocationList.add(Map<String, dynamic>.from(loc));
        }
      }
    }
    setState(() {
      locationListMap = newLocationList;
      if (locationListMap.isNotEmpty) {
        selectedLocation = locationListMap[0];
      } else {
        selectedLocation = {'id': 0, 'name': 'set location'};
      }
    });
  }

  Future<void> onSubmit() async {
    if (selectedLocation['id'] != 0) {
      if (expenseAmount.text.isEmpty) {
        expenseAmount.text = '0.00';
      }
      if (payingAmount.text.isEmpty) {
        payingAmount.text = '0.00';
      }
      var expenseMap = ExpenseManagement().createExpense(
          locId: selectedLocation['id'],
          finalTotal: double.parse(expenseAmount.text),
          amount: double.parse(payingAmount.text),
          method: selectedPaymentMethod['name'],
          accountId: selectedPaymentAccount['id'],
          expenseCategoryId: selectedExpenseCategoryId['id'],
          expenseSubCategoryId: selectedExpenseSubCategoryId['id'],
          taxId: (selectedTax['id'] != 0) ? selectedTax['id'] : null,
          note: expenseNote.text);
      await ExpenseApi().create(expenseMap).then((value) {
        Navigator.pop(context);
        ToastHelper.show(
            context,
            AppLocalizations.of(context)
                .translate('expense_added_successfully'));
      });
    } else {
      ToastHelper.show(context,
          AppLocalizations.of(context).translate('error_invalid_location'));
    }
  }

  Future<void> setTaxMap() async {
    var taxes = await System().get('tax');
    var newTaxList = <Map<String, dynamic>>[
      {'id': 0, 'name': 'Tax rate', 'amount': 0}
    ];
    if (taxes is List) {
      for (var tax in taxes) {
        if (tax is Map) {
          newTaxList.add(Map<String, dynamic>.from(tax));
        }
      }
    }
    setState(() {
      taxListMap = newTaxList;
      selectedTax = taxListMap[0];
    });
  }

  Future<void> setExpenseCategories() async {
    var categories = await ExpenseApi().get();
    var newExpenseCategories = <Map<String, dynamic>>[
      {'id': 0, 'name': 'Select'}
    ];
    for (var cat in categories) {
      if (cat is Map) {
        newExpenseCategories.add(Map<String, dynamic>.from(cat));
      }
    }
    setState(() {
      expenseCategories = newExpenseCategories;
      selectedExpenseCategoryId = expenseCategories[0];

      expenseSubCategories = [
        {'id': 0, 'name': 'Select'}
      ];
      selectedExpenseSubCategoryId = expenseSubCategories[0];
    });
  }

  Future<void> setPaymentDetails(int locId) async {
    var businessDetails = await Helper().getFormattedBusinessDetails();
    setState(() {
      symbol = businessDetails['symbol'] ?? '';
    });

    List payments = await System().get('payment_method', locId);
    var accounts = await System().getPaymentAccounts();

    var newPaymentMethods = <Map<String, dynamic>>[];
    for (var element in payments) {
      if (element is Map) {
        newPaymentMethods.add({
          'name': element['name'],
          'value': element['label'],
          'account_id': (element['account_id'] != null)
              ? int.parse(element['account_id'].toString())
              : null
        });
      }
    }

    var newPaymentAccounts = <Map<String, dynamic>>[
      {'id': null, 'name': "None"}
    ];
    List<String> accIds = [];
    for (var element in accounts) {
      if (element is Map) {
        for (var payment in payments) {
          if (payment is Map &&
              (payment['account_id'].toString() == element['id'].toString()) &&
              !accIds.contains(element['id'].toString())) {
            accIds.add(element['id'].toString());
            newPaymentAccounts.add(Map<String, dynamic>.from(element));
          }
        }
      }
    }

    setState(() {
      paymentMethods = newPaymentMethods;
      if (paymentMethods.isNotEmpty) {
        selectedPaymentMethod = paymentMethods[0];
      } else {
        selectedPaymentMethod = {
          'name': 'name',
          'value': 'value',
          'account_id': null
        };
      }

      paymentAccounts = newPaymentAccounts;
      if (paymentAccounts.isNotEmpty) {
        selectedPaymentAccount = paymentAccounts.firstWhere(
            (element) => element['id'] == selectedPaymentMethod['account_id'],
            orElse: () => paymentAccounts[0]);
      } else {
        selectedPaymentAccount = {'id': null, 'name': "None"};
      }
    });
  }
}
