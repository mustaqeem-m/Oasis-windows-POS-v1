// --- your existing imports ---
import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_2/helpers/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apis/api.dart';
import '../apis/system.dart';
import '../apis/user.dart';
import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/database.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';

int? USERID;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  final _formKey = GlobalKey<FormState>();
  Timer? timer;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage; // 🔴 Error message

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    timer?.cancel();
    super.dispose();
  }

  void _submitLoginForm() {
    if (_formKey.currentState!.validate() && !isLoading) {
      _performLogin();
    }
  }

  Future<void> _performLogin() async {
    if (await Helper().checkConnectivity()) {
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });

      Map? loginResponse;

      try {
        loginResponse = await Api().login(
          usernameController.text,
          passwordController.text,
        );
      } catch (e) {
        setState(() {
          isLoading = false;
          _errorMessage = "Something went wrong. Please try again.";
        });
        return;
      }

      if (loginResponse != null && loginResponse['success'] == true) {
        Helper().jobScheduler();
        showLoadingDialogue();
        await loadAllData(loginResponse, context);
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/home');
      } else {
        setState(() {
          isLoading = false;
          _errorMessage =
              AppLocalizations.of(context).translate('invalid_credentials');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/oasis_pos_logo_.1-1.png',
              fit: BoxFit.contain,
            ),
          ),

          // Blur overlay for glass effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          // Login form
          Align(
            alignment: Alignment(0, 0.6), // Position just above bottom
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: usernameController,
                        style: GoogleFonts.orbitron(color: Colors.black),
                        decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.email_outlined, color: Colors.black),
                          hintText: "Username",
                          hintStyle: GoogleFonts.orbitron(color: Colors.black),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter username" : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_passwordVisible,
                        style: GoogleFonts.orbitron(color: Colors.black),
                        decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.black),
                          hintText: "Password",
                          hintStyle: GoogleFonts.orbitron(color: Colors.black),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter password" : null,
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitLoginForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.shade400,
                            foregroundColor: Colors.white,
                            elevation: 10,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("LOGIN",
                              style: GoogleFonts.orbitron(letterSpacing: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

//! process after user login
  Future<void> loadAllData(loginResponse, context) async {
    timer = Timer.periodic(Duration(seconds: 30), (Timer t) {
      (context != null)
          ? ToastHelper.show(
              context,
              AppLocalizations.of(context)
                  .translate('It_may_take_some_more_time_to_load'))
          : t.cancel();
      t.cancel();
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map loggedInUser = await User().get(loginResponse['access_token']);

    USERID = loggedInUser['id'];
    Config.userId = USERID;
    prefs.setInt('userId', USERID!);
    DbProvider().initializeDatabase(loggedInUser['id']);

    String? lastSync = await System().getProductLastSync();
    final date2 = DateTime.now();

    System().empty();
    Contact().emptyContact();
    await System().insertUserDetails(loggedInUser);
    System().insertToken(loginResponse['access_token']);
    await SystemApi().store();
    await System().insertProductLastSyncDateTimeNow();

    if (prefs.getInt('prevUserId') == null ||
        prefs.getInt('prevUserId') != prefs.getInt('userId')) {
      SellDatabase().deleteSellTables();
      await Variations().refresh();
    } else {
      if (lastSync == null ||
          (date2.difference(DateTime.parse(lastSync)).inHours > 10)) {
        if (await Helper().checkConnectivity()) {
          await Variations().refresh();
          await System().insertProductLastSyncDateTimeNow();
          SellDatabase().deleteSellTables();
        }
      }
    }

    Navigator.of(context).pushReplacementNamed('/home');
    Navigator.of(context).pop();
  }

//! Loading spinner
  Future<void> showLoadingDialogue() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Text(
                    AppLocalizations.of(context).translate('loading_data')),
              ),
            ],
          ),
        );
      },
    );
  }
}
