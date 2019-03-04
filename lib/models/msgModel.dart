import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class msgModel {
  String name;
  String message;
  String time;
  String chat_id;
  int sender_id;
  msgModel({this.message,this.chat_id,this.sender_id});

  factory msgModel.fromJson(Map<dynamic, dynamic> json) {
    return msgModel(
//      name: json['sender_id'] as String,
      message: json['message'] as String,
      chat_id:json['chat_dialog_id'] as String,
      sender_id:json['sender_id'] 

    );
  }
}

List<msgModel> parsePhotos(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<dynamic, dynamic>>();
  return parsed.map<msgModel>((json) => msgModel.fromJson(json)).toList();
}

Future<List<msgModel>> fetchGroupChat(id,http.Client client) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('UserToken');
  print('Id  in ${id}');
  var groups=[];
  final response =
  await client.get("https://api.quickblox.com/chat/Message.json?chat_dialog_id=${id}",
      headers: {"QuickBlox-REST-API-Version":"0.1.1","Content-Type": "application/json","QB-Token":'${token}'});
  // print(response.body);
  var data=jsonDecode(response.body);
  print("DATA in MSG model***:........${data}");
  print('QB-token in service ${token}');
  if(data["items"].length==0){
   data['items']=[{"chat_dialog_id":"${id}","message":""}];//start to send msg
 }
  return compute(parsePhotos,jsonEncode(data['items']));
}




//#my code 
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class MessagesModel {
//   String id;
//   String createdAt;
//   String updatedAt;
//   // String attachments;//list
//   // String readIds; //num list

//   //  String deliveredIds; //num list
//   // String chatDialogId;
//   // String dateSent; //num
//   String message;
//   // String recipientId;

//   //  String senderId;//num
//   // String read;//num

//   MessagesModel({
//     this.id, this.createdAt, this.updatedAt, 
//     // this.attachments, this.readIds,
//   // this.deliveredIds, this.chatDialogId, this.dateSent,
//    this.message, 
//   //  this.recipientId,
//   // this.senderId, this.read
//   });

//   factory MessagesModel.fromJson(Map<String, dynamic> json) {
//     return MessagesModel(
//         id: json['_id'] as String,
//         createdAt: json['created_at'] as String,
//         updatedAt: json['updated_at'] as String,
//         // attachments: json['attachments'] as String,
//         // readIds: json['read_ids'] as String,

//         // deliveredIds: json['delivered_ids'] as String,
//         // chatDialogId: json['chat_dialog_id'] as String,
//         // dateSent: json['attachments'] as String,
//         message: json['read_ids'] as String,

//         // recipientId: json['chat_dialog_id'] as String,
//         // senderId: json['sender_id'] as String,
//         // read: json['read_ids'] as String
//         );
//   }
// }

// List<MessagesModel> parsePhotos(String responseBody) {
//   final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
//   return parsed.map<MessagesModel>((json) => MessagesModel.fromJson(json)).toList();
// }

// Future<List<MessagesModel>> getMessagesData(http.Client client,chatGroupId) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   var token = prefs.getString('UserToken');
//   print('QB-token in messages_model**${token}');
//   // var groups = [];
//   final response =
//       await client.get("https://api.quickblox.com/chat/Message.json?chat_dialog_id=${chatGroupId}", headers: {
//     "QB-Token": '${token}'
//   });
//   var data = jsonDecode(response.body);
//   print('data in message model****:${data}');
//   return compute(parsePhotos, jsonEncode(data));
// }
