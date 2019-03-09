import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupModel {
  String name;
  String message;
  String adminId;
  // String avatarUrl;
  String ids;
  GroupModel({this.name,this.message,this.adminId/* this.time,this.avatarUrl, */,this.ids});

  factory GroupModel.fromJson(Map<dynamic, dynamic> json) {
      return GroupModel(
      name: json['name'] as String,
      message: json['last_message'] as String,
      adminId: json['admin_id'] as String,
    //  avatarUrl: json['photo'] as String,
      ids:json['dialog_id'] as String,
    );
  }
}


List<GroupModel> parsePhotos(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<GroupModel>((json) => GroupModel.fromJson(json)).toList();
}

Future<List<GroupModel>> fetchGroups(http.Client client) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var pin = prefs.getString('userPin');
  var body2=jsonEncode({"PinCode":"${pin}"});
  final response =
  await client.post("http://54.200.143.85:4200/getGroups",
      headers: {"Content-Type": "application/json"},body:body2);
   var data=jsonDecode(response.body);
   var datas= data["data"];
   return compute(parsePhotos,jsonEncode(datas));
}
