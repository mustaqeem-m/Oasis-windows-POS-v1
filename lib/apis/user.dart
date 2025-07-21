import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pos_2/models/system.dart';

import 'api.dart';

class User extends Api {
  Future<Map> get(String? token) async {
    String url = "${apiUrl}user/loggedin";
    var response = await http.get(Uri.parse(url), headers: getHeader(token));
    var userDetails = jsonDecode(response.body);
    Map userDetailsMap = userDetails['data'];
    return userDetailsMap;
  }

  Future<List<dynamic>> getUsersByRole(String role) async {
    try {
      String url = "${apiUrl}users?role=$role";
      var token = await System().getToken();
      var response = await http.get(Uri.parse(url), headers: getHeader(token));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      print(e);
      return [];
    }
  }
}
