import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_2/helpers/toast_helper.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config.dart';
import '../../helpers/AppTheme.dart';
import '../../helpers/SizeConfig.dart';
import '../../helpers/otherHelpers.dart';
import '../../locale/MyLocalizations.dart';
import '../../models/system.dart';
import '../../models/variations.dart';

class HomePageDrawer extends StatefulWidget {
  final String businessLogo;
  final String defaultImage;
  final bool notPermitted;
  final bool accessExpenses;
  final String selectedLanguage;
  final Function(String?) onLanguageChanged;

  const HomePageDrawer({
    super.key,
    required this.businessLogo,
    required this.defaultImage,
    required this.notPermitted,
    required this.accessExpenses,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<HomePageDrawer> createState() => _HomePageDrawerState();
}

class _HomePageDrawerState extends State<HomePageDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).drawerTheme.backgroundColor,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: MySize.scaleFactorHeight! * 250,
              child: DrawerHeader(
                decoration:
                    BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: CachedNetworkImage(
                    fit: BoxFit.fill,
                    errorWidget: (context, url, error) =>
                        Image.asset(widget.defaultImage),
                    placeholder: (context, url) =>
                        Image.asset(widget.defaultImage),
                    imageUrl: widget.businessLogo),
              ),
            ),
            Expanded(
              flex: 9,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Visibility(
                    visible: (widget.notPermitted),
                    child: GestureDetector(
                      onTap: () {
                        AppSettings.openAppSettings();
                      },
                      child: Text(
                        "Allow permissions",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: _changeAppLanguage(),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      "Settings",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  Visibility(
                    visible: widget.accessExpenses,
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.googleSpreadsheet,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onTap: () async {
                        if (await Helper().checkConnectivity()) {
                          Navigator.pushNamed(context, '/expense');
                        } else {
                          ToastHelper.show(
                              context,
                              AppLocalizations.of(context)
                                  .translate('check_connectivity'));
                        }
                      },
                      title: Text(
                        AppLocalizations.of(context).translate('expenses'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.cardAccountDetailsOutline,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('contact_payment'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/contactPayment');
                      } else {
                        ToastHelper.show(
                            context,
                            AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.faceAgent,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('follow_ups'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/followUp');
                      } else {
                        ToastHelper.show(
                            context,
                            AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  Visibility(
                    visible: Config().showFieldForce,
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.humanMale,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onTap: () async {
                        if (await Helper().checkConnectivity()) {
                          Navigator.pushNamed(context, '/fieldForce');
                        } else {
                          ToastHelper.show(
                              context,
                              AppLocalizations.of(context)
                                  .translate('check_connectivity'));
                        }
                      },
                      title: Text(
                        AppLocalizations.of(context)
                            .translate('field_force_visits'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.contact_phone_outlined,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('contacts'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/leads');
                      } else {
                        ToastHelper.show(
                            context,
                            AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.local_shipping_outlined,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('shipment'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/shipment');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.syncIcon,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).cardColor,
                              content: Row(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary),
                                  ),
                                  Container(
                                      margin: const EdgeInsets.only(left: 15),
                                      child: Text(
                                          AppLocalizations.of(context)
                                              .translate('loading_data'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface))),
                                ],
                              ),
                            );
                          },
                        );
                        await Variations().refresh();
                        System().refresh().then((value) {
                          Navigator.popUntil(
                              context, ModalRoute.withName('/home'));
                        });
                      } else {
                        ToastHelper.show(
                            context,
                            AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                    title: Text(
                      AppLocalizations.of(context).translate('refresh'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                flex: 1,
                child: Container(
                    alignment: Alignment.bottomCenter,
                    margin: const EdgeInsets.all(10),
                    child: Text(
                      "${Config().copyright}  ${Config().appName}  ${Config().version}",
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontWeight: FontWeight.normal),
                    )))
          ],
        ),
      ),
    );
  }

  Widget _changeAppLanguage() {
    return ChangeNotifierProvider(
      create: (context) => AppLanguage(),
      child: Consumer<AppLanguage>(
        builder: (context, appLanguage, child) {
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Theme.of(context).cardColor,
              onChanged: (String? newValue) {
                widget.onLanguageChanged(newValue);
                final selectedLangMap = Config().lang.firstWhere(
                      (element) => element['languageCode'] == newValue,
                      orElse: () => {'languageCode': 'en', 'countryCode': 'US'},
                    );
                appLanguage.changeLanguage(Locale(
                    selectedLangMap['languageCode']!,
                    selectedLangMap['countryCode']));
                Navigator.pushReplacementNamed(context, '/splash');
              },
              value: widget.selectedLanguage,
              items: Config().lang.map<DropdownMenuItem<String>>((Map locale) {
                return DropdownMenuItem<String>(
                  value: locale['languageCode'],
                  child: Text(
                    locale['name'],
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
