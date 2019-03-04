// import 'package:flutter/material.dart';
// import '../../models/msgModel.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'ChatPage.dart';

// class ChatScreenState extends StatelessWidget {
// //  final String title;
//   final String chatTitle;
//   final String groupChatId;
//   ChatScreenState({Key key, this.chatTitle, this.groupChatId}) : super(key: key);

// @override
//   void initState() {}
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder<List<msgModel>>(
//         future: fetchGroupChat("${this.groupChatId}",http.Client()),
//         builder: (context, snapshot) {
//           // print("Snapshot...${snapshot}");
//           if (snapshot.hasError) print("Error....${snapshot.error}");
//           return snapshot.hasData
//               ? ChatPage(posts: snapshot.data,chatTitle:this.chatTitle)
//               : Center(child: CircularProgressIndicator());
//         },
//       ),
//     );
//   }
// }