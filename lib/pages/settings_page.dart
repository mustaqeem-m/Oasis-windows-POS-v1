import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dropdown Settings'),
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Show Commission Agent'),
                value: provider.dropdownVisibilities['showCommissionAgent']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility(
                      'showCommissionAgent', value);
                },
              ),
              SwitchListTile(
                title: const Text('Show Types of Service'),
                value: provider.dropdownVisibilities['showTypesOfService']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility(
                      'showTypesOfService', value);
                },
              ),
              SwitchListTile(
                title: const Text('Show Table'),
                value: provider.dropdownVisibilities['showTable']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility('showTable', value);
                },
              ),
              SwitchListTile(
                title: const Text('Show Service Staff'),
                value: provider.dropdownVisibilities['showServiceStaff']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility('showServiceStaff', value);
                },
              ),
              SwitchListTile(
                title: const Text('Show Printer'),
                value: provider.dropdownVisibilities['showPrinter']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility('showPrinter', value);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Receipt Paper Size'),
                trailing: DropdownButton<String>(
                  dropdownColor: Colors.white,
                  value: provider.selectedPaperSize,
                  items: <String>['2-inch', '3-inch', '3-inch-alt']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      provider.updatePaperSize(newValue);
                    }
                  },
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show Kitchen Order'),
                value: provider.dropdownVisibilities['showKitchenOrder']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility('showKitchenOrder', value);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show Repair Button'),
                value: provider.showRepairButton,
                onChanged: (bool value) {
                  provider.toggleRepairButtonVisibility(value);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show Price Type Dropdown'),
                value: provider.dropdownVisibilities['showPriceTypeDropdown']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility(
                      'showPriceTypeDropdown', value);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
