import 'package:flutter/material.dart';
import 'package:pos_2/apis/user.dart';
import 'package:pos_2/helpers/AppTheme.dart';
import 'package:pos_2/helpers/SizeConfig.dart';
import 'package:pos_2/locale/MyLocalizations.dart';
import 'package:pos_2/models/system.dart';

class ShippingModal extends StatefulWidget {
  final String? shippingDetails;
  final String? shippingAddress;
  final String? shippingCharges;
  final String? shippingStatus;
  final String? deliveredTo;
  final String? deliveryPerson;

  const ShippingModal({
    super.key,
    this.shippingDetails,
    this.shippingAddress,
    this.shippingCharges,
    this.shippingStatus,
    this.deliveredTo,
    this.deliveryPerson,
  });

  @override
  _ShippingModalState createState() => _ShippingModalState();
}

class _ShippingModalState extends State<ShippingModal> {
  late TextEditingController _shippingDetailsController;
  late TextEditingController _shippingAddressController;
  late TextEditingController _shippingChargesController;
  late TextEditingController _deliveredToController;

  String? _selectedStatus;
  String? _selectedDeliveryPerson;
  bool _isLoadingDeliveryPersons = true;

  final List<String> _shippingStatuses = [
    'Ordered',
    'Packed',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  List<Map<String, dynamic>> _deliveryPersons = [];

  @override
  void initState() {
    super.initState();
    _shippingDetailsController =
        TextEditingController(text: widget.shippingDetails);
    _shippingAddressController =
        TextEditingController(text: widget.shippingAddress);
    _shippingChargesController =
        TextEditingController(text: widget.shippingCharges);
    _deliveredToController = TextEditingController(text: widget.deliveredTo);
    _selectedStatus = widget.shippingStatus ?? _shippingStatuses.first;
    _fetchDeliveryPersons();
  }

  Future<void> _fetchDeliveryPersons() async {
    setState(() {
      _isLoadingDeliveryPersons = true;
    });
    final deliveryPersons = await System().get('serviceStaff');
    setState(() {
      _deliveryPersons = deliveryPersons.map<Map<String, String>>((user) {
        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        return {
          'id': user['id'].toString(),
          'name': '$firstName $lastName'.trim(),
        };
      }).toList();

      if (_deliveryPersons.isNotEmpty) {
        final validIds = _deliveryPersons.map((p) => p['id']).toSet();
        if (widget.deliveryPerson != null &&
            validIds.contains(widget.deliveryPerson)) {
          _selectedDeliveryPerson = widget.deliveryPerson;
        } else {
          _selectedDeliveryPerson = _deliveryPersons.first['id'];
        }
      }

      _isLoadingDeliveryPersons = false;
    });
  }

  @override
  void dispose() {
    _shippingDetailsController.dispose();
    _shippingAddressController.dispose();
    _shippingChargesController.dispose();
    _deliveredToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return AlertDialog(
      title: Text(AppLocalizations.of(context).translate('shipping')),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MySize.screenWidth! * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildForm(themeData),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            final result = {
              'shippingDetails': _shippingDetailsController.text,
              'shippingAddress': _shippingAddressController.text,
              'shippingCharges': _shippingChargesController.text,
              'shippingStatus': _selectedStatus,
              'deliveredTo': _deliveredToController.text,
              'deliveryPerson': _selectedDeliveryPerson,
            };
            Navigator.of(context).pop(result);
          },
          child: Text(AppLocalizations.of(context).translate('update')),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData themeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextarea(
                controller: _shippingDetailsController,
                labelText:
                    '${AppLocalizations.of(context).translate('shipping_details')}*',
              ),
            ),
            SizedBox(width: MySize.size16),
            Expanded(
              child: _buildTextarea(
                controller: _shippingAddressController,
                labelText:
                    AppLocalizations.of(context).translate('shipping_address'),
              ),
            ),
          ],
        ),
        SizedBox(height: MySize.size16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _shippingChargesController,
                labelText:
                    '${AppLocalizations.of(context).translate('shipping_charges')}*',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: MySize.size16),
            Expanded(
              child: _buildDropdown(
                value: _selectedStatus,
                items: _shippingStatuses.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                labelText:
                    AppLocalizations.of(context).translate('shipping_status'),
              ),
            ),
          ],
        ),
        SizedBox(height: MySize.size16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _deliveredToController,
                labelText:
                    AppLocalizations.of(context).translate('delivered_to'),
              ),
            ),
            SizedBox(width: MySize.size16),
            Expanded(
              child: _isLoadingDeliveryPersons
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdown(
                      value: _selectedDeliveryPerson,
                      items: _deliveryPersons.map((person) {
                        return DropdownMenuItem<String>(
                          value: person['id'],
                          child: Text(person['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDeliveryPerson = value;
                        });
                      },
                      labelText: AppLocalizations.of(context)
                          .translate('delivery_person'),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTextarea({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String labelText,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      dropdownColor: Colors.white,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
    );
  }
}
