import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../models/user.dart';
import 'package:http/http.dart' as http;
import 'chatsList.dart';
import '../../../ProfilePage/profile.dart';

import '../SongList//audioListHome.dart'; //remove

class ChatScreenState extends StatefulWidget {
  final ScrollController hideButtonController;

  ChatScreenState({@required this.hideButtonController, Key key})
      : super(key: key);

  @override
  ChatScreenStateState createState() {
    return new ChatScreenStateState();
  }
}

class ChatScreenStateState extends State<ChatScreenState> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Oye Yaaro"),
        actions: <Widget>[
          _menuBuilder(),
          // IconButton(icon: Icon(Icons.album),onPressed: (){Navigator.push(context,MaterialPageRoute(builder: (context) => AudioList(),));},),//remove
        ],
        backgroundColor: Color(0xffb00bae3),
      ),
      body: FutureBuilder<List<ChatModel>>(
        future: fetchPrivateChat(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print("Error....${snapshot.error}");
          print('chat list data : ${snapshot}');
          return snapshot.hasData
              ? snapshot.data.length != 0
                  ? ListViewPosts(
                      posts: snapshot.data,
                      hideButtonController: widget.hideButtonController,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('No Chat History Available',style:TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xffb00bae3),
                        )),
                        // Text('Start New Chat')
                        ],
                    ))
              : Center(child: CircularProgressIndicator());
        },
      ),
      // floatingActionButton: new FloatingActionButton(
      //   backgroundColor: Theme.of(context).accentColor,
      //   child:
      //   Image(
      //     image: new AssetImage("assets/searchGroup.png"),
      //     width: 45.0,
      //     height: 45.0,
      //     fit: BoxFit.scaleDown,
      //     alignment: Alignment.center,
      //   ),

      //   // Icon(
      //   //   Icons.search,
      //   //   color: Colors.white,
      //   // ),
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => CreateGroup(),
      //       ),
      //     );
      //   },
      // ),
    );
  }

  Widget _menuBuilder() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.white,
      ),
      tooltip: "Menu",
      onSelected: _onMenuItemSelect,
      itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'Profile',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  children: <Widget>[
                    Text("Profile"),
                    Spacer(),
                    Icon(Icons.person),
                  ],
                ),
              ),
            ),
          ],
    );
  }

  _onMenuItemSelect(String option) {
    switch (option) {
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
                  userPin: currentUser.userId,
                ),
          ),
        );
        break;
    }
  }
}
