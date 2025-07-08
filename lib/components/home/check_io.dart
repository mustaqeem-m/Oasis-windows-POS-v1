import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pos_2/pages/login.dart';

import '../../helpers/SizeConfig.dart';
import '../../helpers/otherHelpers.dart';
import '../../helpers/toast_helper.dart';
import '../../locale/MyLocalizations.dart';
import '../../models/attendance.dart';

class CheckIO extends StatefulWidget {
  final bool? checkedIn;
  final DateTime clockInTime;
  final Function(bool) onCheckInOut;

  const CheckIO({
    super.key,
    required this.checkedIn,
    required this.clockInTime,
    required this.onCheckInOut,
  });

  @override
  State<CheckIO> createState() => _CheckIOState();
}

class _CheckIOState extends State<CheckIO> {
  final note = TextEditingController();
  LatLng? currentLoc;

  @override
  Widget build(BuildContext context) {
    if (widget.checkedIn != null) {
      return Padding(
        padding: EdgeInsets.only(top: MySize.size20!),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: (!widget.checkedIn!)
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () async {
                Helper().syncCallLogs();
                showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        title: Text(
                            (!widget.checkedIn!)
                                ? AppLocalizations.of(context)
                                    .translate('check_in_note')
                                : AppLocalizations.of(context)
                                    .translate('check_out_note'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold)),
                        content: TextFormField(
                            controller: note,
                            autofocus: true,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (await Helper().checkConnectivity()) {
                                try {
                                  await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.high)
                                      .then((Position position) {});
                                } catch (e) {}
                                if (widget.checkedIn == false) {
                                  var ipAddress =
                                      IpAddress(type: RequestType.json);
                                  dynamic data = await ipAddress.getIpAddress();
                                  String iP = data.toString();

                                  try {
                                    await Geolocator.getCurrentPosition(
                                            desiredAccuracy:
                                                LocationAccuracy.high)
                                        .then((Position position) {
                                      currentLoc = LatLng(position.latitude,
                                          position.longitude);
                                    });
                                  } catch (e) {}

                                  var checkInMap = await Attendance().doCheckIn(
                                      checkInNote: note.text,
                                      iPAddress: iP,
                                      latitude: (currentLoc != null)
                                          ? currentLoc!.latitude
                                          : '',
                                      longitude: (currentLoc != null)
                                          ? currentLoc!.longitude
                                          : '');
                                  ToastHelper.show(context, checkInMap);
                                  note.clear();
                                } else {
                                  try {
                                    await Geolocator.getCurrentPosition(
                                            desiredAccuracy:
                                                LocationAccuracy.high)
                                        .then((Position position) {
                                      currentLoc = LatLng(position.latitude,
                                          position.longitude);
                                    });
                                  } catch (e) {}

                                  var checkOutMap = await Attendance()
                                      .doCheckOut(
                                          latitude: (currentLoc != null)
                                              ? currentLoc!.latitude
                                              : '',
                                          longitude: (currentLoc != null)
                                              ? currentLoc!.longitude
                                              : '',
                                          checkOutNote: note.text);
                                  ToastHelper.show(context, checkOutMap);
                                  note.clear();
                                }
                                widget.onCheckInOut(await Attendance()
                                    .getAttendanceStatus(USERID));
                              } else
                                ToastHelper.show(
                                    context,
                                    AppLocalizations.of(context)
                                        .translate('check_connectivity'));
                            },
                            child: Text(
                                AppLocalizations.of(context).translate('ok'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                                AppLocalizations.of(context)
                                    .translate('cancel'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                          )
                        ],
                      );
                    });
              },
              child: Text(
                  (!widget.checkedIn!)
                      ? AppLocalizations.of(context).translate('check_in')
                      : AppLocalizations.of(context).translate('check_out'),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: (!widget.checkedIn!)
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            const SizedBox(height: 10),
            Text(
                (!widget.checkedIn!)
                    ? ''
                    : DateTime.now().difference(widget.clockInTime).toString(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    )),
          ],
        ),
      );
    } else
      return Container();
  }
}
