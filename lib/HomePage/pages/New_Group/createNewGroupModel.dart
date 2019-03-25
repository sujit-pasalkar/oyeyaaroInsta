import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _CreateGroupModel createNewGroup = _CreateGroupModel();

class _CreateGroupModel {
  getStudentList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPin = prefs.getString('userPin');

    http.Response response = await http.post(
        "http://oyeyaaroapi.plmlogix.com/studentList",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userPin": userPin}));
    var res = jsonDecode(response.body);
    return res['data'];
  }

  Future<bool> createGroup(g_nm, occ_id) async {
    print('$g_nm, ${occ_id}');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPin = prefs.getString('userPin');

    http.Response response = await http.post(
        "http://oyeyaaroapi.plmlogix.com/createGroup",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "group_name": g_nm,
          "occupants_ids": occ_id,
          "admin_id": userPin
        }));
    var res = jsonDecode(response.body);
    print('create group res :$res');
    if (res['success']) {
      return true;
    } else
      return false;
  }

}
