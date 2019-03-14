import 'package:flutter/material.dart';
import 'imageAlbum.dart';
import 'videoAlbum.dart';
import '../../../ProfilePage/profile.dart';
import '../../../models/user.dart';

class NetworkScreen extends StatefulWidget {
  final ScrollController hideButtonController;
  final  String dialogId ;

  NetworkScreen({@required this.hideButtonController, @required this.dialogId, key}) : super(key: key);

  @override
  _NetworkScreenState createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, initialIndex: 0, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Oye Yaaro"),
        actions: <Widget>[
          _menuBuilder(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Color(0xffb00bae3),
          tabs: <Widget>[
            new Tab(
              text: "IMAGES",
            ),
            new Tab(
              text: "VIDEOS",
            ),
          ],
        ),
        backgroundColor: Color(0xffb00bae3),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          ImagesPage(hideButtonController: widget.hideButtonController,dialogId:widget.dialogId),
          VideosPage(hideButtonController: widget.hideButtonController,dialogId:widget.dialogId),
        ],
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
          ],
    );
  }

  _onMenuItemSelect(String option) {
    switch (option) {
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userPin: currentUser.userId,),
          ),
        );
        break;
    }
  }
}
