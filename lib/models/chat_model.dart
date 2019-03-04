import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatModel {
  bool isNowImg;
  String receiverName;
  String message;
  String time;
  String senderName;
  String chat_id;
  String receiverPin;
  String receiverPhone;
  List senderGroup;
  ChatModel({this.isNowImg,this.receiverName,this.message,this.receiverPin,this.time,this.senderName,this.chat_id,this.receiverPhone,
  this.senderGroup
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      isNowImg: json['isNowImg'] as bool,
      receiverName: json['receiverName'] as String,
      message: json['last_message'] as String,
      receiverPin:json['receiverPin'] as String,
      time:json['last_message_date_sent'] as String,
      receiverPhone:json['receiverNumber'] as String ,
      senderName: json['senderName'] as String,
      chat_id:json['chat_id'] as String,
      senderGroup:json['senderGroup'] as List,
    );
  }
}


List<ChatModel> parsePhotos(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<ChatModel>((json) => ChatModel.fromJson(json)).toList();
}

Future<List<ChatModel>> fetchPrivateChat(http.Client client) async {
  var arr=[];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var pin = prefs.getString('userPin');
  print('Pin in $pin');

  var body2=jsonEncode({"senderPin":"$pin"});
  final response =
  await client.post("http://54.200.143.85:4200/fetchChats",
      headers: {"Content-Type": "application/json"},body:body2);
  print(response.body);
  var data=jsonDecode(response.body);
 arr=data["data"];
 print('chat list data : ${arr}');
 for(var i=0;i<arr.length;i++){
   if(arr[i]["receiverPin"]==pin)
     {
       arr[i]["receiverPin"]=arr[i]["senderPin"];
       arr[i]["receiverNumber"]=arr[i]["senderNumber"];
       arr[i]["receiverName"]=arr[i]["senderName"];
     }
 }
  return compute(parsePhotos,jsonEncode(data["data"]));
}