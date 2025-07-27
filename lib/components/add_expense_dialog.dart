import 'package:pos_2/models/system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_2/apis/expenses.dart';
import 'package:pos_2/apis/system.dart';
import 'package:pos_2/helpers/otherHelpers.dart';
import 'package:pos_2/models/expenses.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({Key? key}) : super(key: key);

  @override
  _AddExpenseDialogState createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  List<Map<String, dynamic>> expenseCategories = [],
      expenseSubCategories = [],
      paymentMethods = [],
      paymentAccounts = [],
      locationListMap = [],
      taxListMap = [],
      expenseForUsers = [];

  Map<String, dynamic> selectedLocation = {};
  Map<String, dynamic> selectedTax = {};
  Map<String, dynamic> selectedExpenseCategory = {};
  Map<String, dynamic> selectedExpenseSubCategory = {};
  Map<String, dynamic> selectedExpenseFor = {};
  Map<String, dynamic> selectedPaymentAccount = {};
  Map<String, dynamic> selectedPaymentMethod = {};

  TextEditingController refNoController = TextEditingController();
  TextEditingController expenseAmountController = TextEditingController();
  TextEditingController expenseNoteController = TextEditingController();
  TextEditingController payingAmountController = TextEditingController();
  TextEditingController paymentNoteController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  DateTime paidOnDate = DateTime.now();
  double totalAmount = 0.0;
  double paidAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    expenseAmountController.addListener(_updatePaymentDue);
    payingAmountController.addListener(_updatePaymentDue);
  }

  @override
  void dispose() {
    refNoController.dispose();
    expenseAmountController.dispose();
    expenseNoteController.dispose();
    payingAmountController.dispose();
    paymentNoteController.dispose();
    expenseAmountController.removeListener(_updatePaymentDue);
    payingAmountController.removeListener(_updatePaymentDue);
    super.dispose();
  }

  void _updatePaymentDue() {
    setState(() {
      totalAmount = double.tryParse(expenseAmountController.text) ?? 0.0;
      paidAmount = double.tryParse(payingAmountController.text) ?? 0.0;
    });
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    await _fetchLocations();
    await _fetchTaxes();
    await _fetchExpenseCategories();
    await _fetchExpenseForUsers();

    // Initialize payment dropdowns with default "select" values
    paymentMethods = [
      {'name': 'name', 'value': 'Select Method', 'account_id': null}
    ];
    selectedPaymentMethod = paymentMethods.first;
    paymentAccounts = [
      {'id': null, 'name': "None"}
    ];
    selectedPaymentAccount = paymentAccounts.first;

    expenseSubCategories = [
      {'id': 0, 'name': 'Select Sub Category'}
    ];
    selectedExpenseSubCategory = expenseSubCategories.first;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchLocations() async {
    var locations = await System().get('location');
    locationListMap = [
      {'id': 0, 'name': 'Select Location'}
    ];
    if (locations is List) {
      locationListMap.addAll(List<Map<String, dynamic>>.from(locations));
    }
    selectedLocation = locationListMap.first;
  }

  Future<void> _fetchTaxes() async {
    var taxes = await System().get('tax');
    taxListMap = [
      {'id': 0, 'name': 'Select Tax', 'amount': 0}
    ];
    if (taxes is List) {
      taxListMap.addAll(List<Map<String, dynamic>>.from(taxes));
    }
    selectedTax = taxListMap.first;
  }

  Future<void> _fetchExpenseCategories() async {
    var categories = await ExpenseApi().get();
    expenseCategories = [
      {'id': 0, 'name': 'Select Category'}
    ];
    if (categories is List) {
      expenseCategories.addAll(List<Map<String, dynamic>>.from(categories));
    }
    selectedExpenseCategory = expenseCategories.first;
  }

  Future<void> _fetchExpenseForUsers() async {
    var users = await System().get('users');
    expenseForUsers = [
      {'id': 0, 'name': 'Select User'}
    ];
    if (users is List) {
      expenseForUsers.addAll(List<Map<String, dynamic>>.from(users));
    }
    selectedExpenseFor = expenseForUsers.first;
  }

  Future<void> _fetchPaymentDetails(int locationId) async {
    if (locationId == 0) {
      setState(() {
        paymentMethods = [
          {'name': 'name', 'value': 'Select Method', 'account_id': null}
        ];
        selectedPaymentMethod = paymentMethods.first;
        paymentAccounts = [
          {'id': null, 'name': "None"}
        ];
        selectedPaymentAccount = paymentAccounts.first;
      });
      return;
    }

    List payments = await System().get('payment_method', locationId);
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
        selectedPaymentMethod = paymentMethods.first;
      } else {
        paymentMethods = [
          {'name': 'name', 'value': 'Select Method', 'account_id': null}
        ];
        selectedPaymentMethod = paymentMethods.first;
      }

      paymentAccounts = newPaymentAccounts;
      if (paymentAccounts.isNotEmpty) {
        selectedPaymentAccount = paymentAccounts.firstWhere(
            (element) => element['id'] == selectedPaymentMethod['account_id'],
            orElse: () => paymentAccounts.first);
      } else {
        paymentAccounts = [
          {'id': null, 'name': "None"}
        ];
        selectedPaymentAccount = paymentAccounts.first;
      }
    });
  }

  Future<void> _selectDate(BuildContext context,
      {bool isPaidOn = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPaidOn ? paidOnDate : selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPaidOn) {
          paidOnDate = picked;
        } else {
          selectedDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (selectedLocation['id'] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a business location.')));
        return;
      }

      var expenseData = ExpenseManagement().createExpense(
        locId: selectedLocation['id'],
        finalTotal: totalAmount,
        amount: paidAmount,
        method: selectedPaymentMethod['name'],
        accountId: selectedPaymentAccount['id'],
        expenseCategoryId: selectedExpenseCategory['id'],
        expenseSubCategoryId: selectedExpenseSubCategory['id'],
        taxId: selectedTax['id'] != 0 ? selectedTax['id'] : null,
        note: expenseNoteController.text,
        refNo: refNoController.text,
        expenseFor: selectedExpenseFor['id'],
        transactionDate: selectedDate.toIso8601String(),
        paymentNote: paymentNoteController.text,
      );

      await ExpenseApi().create(expenseData).then((_) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }).catchError((error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add expense: $error')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdown('Business Location*', locationListMap,
                          selectedLocation, (value) {
                        setState(() {
                          selectedLocation = value!;
                          _fetchPaymentDetails(selectedLocation['id']);
                        });
                      }),
                      _buildDropdown('Expense Category*', expenseCategories,
                          selectedExpenseCategory, (value) {
                        setState(() {
                          selectedExpenseCategory = value!;
                          selectedExpenseSubCategory = {
                            'id': 0,
                            'name': 'Select Sub Category'
                          };
                          if (value.containsKey('sub_categories') &&
                              value['sub_categories'] is List) {
                            expenseSubCategories = [
                              {'id': 0, 'name': 'Select Sub Category'}
                            ];
                            expenseSubCategories.addAll(
                                List<Map<String, dynamic>>.from(
                                    value['sub_categories']));
                          } else {
                            expenseSubCategories = [
                              {'id': 0, 'name': 'Select Sub Category'}
                            ];
                          }
                        });
                      }),
                      _buildDropdown('Sub Category', expenseSubCategories,
                          selectedExpenseSubCategory, (value) {
                        setState(() {
                          selectedExpenseSubCategory = value!;
                        });
                      }),
                      _buildTextField(refNoController, 'Reference No',
                          'Leave empty to auto-generate'),
                      _buildDateTimePicker(
                          'Date*', selectedDate, () => _selectDate(context)),
                      _buildDropdown(
                          'Expense for', expenseForUsers, selectedExpenseFor,
                          (value) {
                        setState(() {
                          selectedExpenseFor = value!;
                        });
                      }),
                      _buildDropdown('Applicable Tax', taxListMap, selectedTax,
                          (value) {
                        setState(() {
                          selectedTax = value!;
                        });
                      }),
                      _buildTextField(
                          expenseAmountController, 'Total Amount*', null,
                          isNumeric: true),
                      _buildTextField(
                          expenseNoteController, 'Expense Note', null,
                          maxLines: 3),
                      const Divider(height: 30, thickness: 1),
                      const Text('Add Payment',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildTextField(payingAmountController, 'Amount*', null,
                          isNumeric: true),
                      _buildDateTimePicker('Paid On*', paidOnDate,
                          () => _selectDate(context, isPaidOn: true)),
                      _buildDropdown('Payment Method*', paymentMethods,
                          selectedPaymentMethod, (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                          selectedPaymentAccount = paymentAccounts.firstWhere(
                              (acc) => acc['id'] == value['account_id'],
                              orElse: () => paymentAccounts.isNotEmpty
                                  ? paymentAccounts.first
                                  : {'id': null, 'name': 'None'});
                        });
                      }, itemValue: 'value'),
                      _buildDropdown('Payment Account', paymentAccounts,
                          selectedPaymentAccount, (value) {
                        setState(() {
                          selectedPaymentAccount = value!;
                        });
                      }),
                      _buildTextField(
                          paymentNoteController, 'Payment Note', null,
                          maxLines: 3),
                      const SizedBox(height: 20),
                      Text('Payment Due: ${totalAmount - paidAmount}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label,
      List<Map<String, dynamic>> items,
      Map<String, dynamic> selectedValue,
      ValueChanged<Map<String, dynamic>?> onChanged,
      {String itemValue = 'name'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: selectedValue,
        items: items.map((item) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: item,
            child: Text(item[itemValue] ?? '...'),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (label.endsWith('*') &&
              (value == null || value['id'] == 0 || value['id'] == null)) {
            return 'This field is required.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String? hint,
      {bool isNumeric = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: (value) {
          if (label.endsWith('*') && (value == null || value.isEmpty)) {
            return 'This field is required.';
          }
          if (isNumeric &&
              value != null &&
              value.isNotEmpty &&
              double.tryParse(value) == null) {
            return 'Please enter a valid number.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateTimePicker(
      String label, DateTime date, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text('$label: ${DateFormat.yMd().format(date)}'),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
