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
                  provider.updateDropdownVisibility('showCommissionAgent', value);
                },
              ),
              SwitchListTile(
                title: const Text('Show Types of Service'),
                value: provider.dropdownVisibilities['showTypesOfService']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility('showTypesOfService', value);
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
              SwitchListTile(
                title: const Text('Show Kitchen Order'),
                value: provider.dropdownVisibilities['showKitchenOrder']!,
                onChanged: (bool value) {
                  provider.updateDropdownVisibility('showKitchenOrder', value);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
