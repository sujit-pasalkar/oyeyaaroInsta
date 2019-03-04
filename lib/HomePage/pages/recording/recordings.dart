import 'package:flutter/material.dart';
import '../../../ProfilePage/profile.dart';
import '../../../models/user.dart';
import 'audio.dart';
import 'video.dart';

class RecordingScreen extends StatefulWidget {
  final ScrollController hideButtonController;

  RecordingScreen({@required this.hideButtonController, Key key}) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
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
            Tab(
              text: "Video",
            ),
            Tab(
              text: "Audio",
            ),
          ],
        ),
        backgroundColor: Color(0xffb00bae3),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          VedioRecordingScreen(hideButtonController: widget.hideButtonController),
          AudioRecordingScreen(hideButtonController: widget.hideButtonController),
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
