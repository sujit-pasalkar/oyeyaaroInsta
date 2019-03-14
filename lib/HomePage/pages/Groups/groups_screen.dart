import 'package:flutter/material.dart';
import '../../../models/group_model.dart';
import '../../../models/user.dart';
import 'package:http/http.dart' as http;
import 'groupsList.dart';
import '../New_Group/createGroup.dart';
import '../../../ProfilePage/profile.dart';
import '../New_Group/createNewGroup.dart';

class GroupScreenState extends StatefulWidget {
  final ScrollController hideButtonController;

  GroupScreenState({@required this.hideButtonController, Key key})
      : super(key: key);

  @override
  GroupScreenStateState createState() {
    return new GroupScreenStateState();
  }
}

class GroupScreenStateState extends State<GroupScreenState> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Oye Yaaro"),
        actions: <Widget>[
          _menuBuilder(),
        ],
        backgroundColor: Color(0xffb00bae3),
      ),
      resizeToAvoidBottomPadding: true,
      body: FutureBuilder<List<GroupModel>>(
        future: fetchGroups(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print("Error....${snapshot.error}");
          return snapshot.hasData
              ? ListViewPosts(
                  posts: snapshot.data,
                  hideButtonController: widget.hideButtonController,
                )
              : Center(child: CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(
                        Color(0xffb00bae3))));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        backgroundColor: Color(0xffb00bae3),
        child: Image(
          image: new AssetImage("assets/test.png"),
          width: 35.0,
          height: 35.0,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGroup(),
            ),
          );
        },
      ),
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
            PopupMenuItem<String>(
              value: 'Create New Group',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  children: <Widget>[
                    Text("Create New Group"),
                    Spacer(),
                    Icon(Icons.group_add),
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
        case 'Create New Group':
        {
          print('create grp');
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNewGroup(),
            ));
        }
        break;
    }
  }
}
