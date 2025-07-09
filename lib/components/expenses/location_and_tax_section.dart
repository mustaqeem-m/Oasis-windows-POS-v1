import 'package:flutter/material.dart';
import '../../helpers/SizeConfig.dart';
import '../../locale/MyLocalizations.dart';

class LocationAndTaxSection extends StatelessWidget {
  final Map<String, dynamic> selectedLocation;
  final List<Map<String, dynamic>> locationListMap;
  final Function(Map<String, dynamic>?) onLocationChanged;
  final Map<String, dynamic> selectedTax;
  final List<Map<String, dynamic>> taxListMap;
  final Function(Map<String, dynamic>?) onTaxChanged;
  final ThemeData themeData;

  const LocationAndTaxSection({
    super.key,
    required this.selectedLocation,
    required this.locationListMap,
    required this.onLocationChanged,
    required this.selectedTax,
    required this.taxListMap,
    required this.onTaxChanged,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
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
            onChanged: onLocationChanged,
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
            onChanged: onTaxChanged,
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
}
