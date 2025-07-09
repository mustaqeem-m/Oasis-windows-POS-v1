import 'package:flutter/material.dart';

import 'package:pos_2/helpers/toast_helper.dart';

import '../apis/expenses.dart';
import '../components/expenses/expense_details_card.dart';
import '../components/expenses/location_and_tax_section.dart';
import '../components/expenses/payment_card.dart';
import '../components/expenses/submit_button.dart';
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
                    LocationAndTaxSection(
                      selectedLocation: selectedLocation,
                      locationListMap: locationListMap,
                      onLocationChanged: (item) {
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
                      selectedTax: selectedTax,
                      taxListMap: taxListMap,
                      onTaxChanged: (item) {
                        if (item != null) {
                          setState(() {
                            selectedTax = item;
                          });
                        }
                      },
                      themeData: themeData,
                    ),
                    SizedBox(height: MySize.size24!),
                    ExpenseDetailsCard(
                      themeData: themeData,
                      selectedExpenseCategoryId: selectedExpenseCategoryId,
                      expenseCategories: expenseCategories,
                      onExpenseCategoryChanged: (item) {
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
                      selectedExpenseSubCategoryId: selectedExpenseSubCategoryId,
                      expenseSubCategories: expenseSubCategories,
                      onExpenseSubCategoryChanged: (item) {
                        if (item != null) {
                          setState(() {
                            selectedExpenseSubCategoryId = item;
                          });
                        }
                      },
                      expenseAmount: expenseAmount,
                      symbol: symbol,
                      expenseNote: expenseNote,
                    ),
                    SizedBox(height: MySize.size24!),
                    PaymentCard(
                      themeData: themeData,
                      payingAmount: payingAmount,
                      symbol: symbol,
                      payingAmountValidator: (value) {
                        if (value == null || value.isEmpty) value = '0.00';
                        if (expenseAmount.text.isEmpty ||
                            double.tryParse(value) == null ||
                            double.parse(value) > double.parse(expenseAmount.text)) {
                          return AppLocalizations.of(context)
                              .translate('enter_valid_payment_amount');
                        }
                        return null;
                      },
                      selectedPaymentMethod: selectedPaymentMethod,
                      paymentMethods: paymentMethods,
                      onPaymentMethodChanged: (item) {
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
                      selectedPaymentAccount: selectedPaymentAccount,
                      paymentAccounts: paymentAccounts,
                      onPaymentAccountChanged: (item) {
                        if (item != null) {
                          setState(() {
                            selectedPaymentAccount = item;
                            selectedPaymentMethod['account_id'] = item['id'];
                          });
                        }
                      },
                    ),
                    SizedBox(height: MySize.size24!),
                    SubmitButton(
                      themeData: themeData,
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
                    ),
                  ],
                ),
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