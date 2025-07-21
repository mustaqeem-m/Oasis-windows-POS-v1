import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_2/apis/api.dart';
import 'package:pos_2/models/system.dart';

class TableApi extends Api {
  Future<List<dynamic>> get() async {
    String url = this.apiUrl + "table";
    String? token = await System().getToken();
    var response = await http.get(Uri.parse(url), headers: this.getHeader(token));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['data'];
    }
    return [];
  }
}
