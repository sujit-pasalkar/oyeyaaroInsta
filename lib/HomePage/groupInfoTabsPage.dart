import 'package:flutter/material.dart';
import 'GroupInfoTabs/joined.dart';
import 'GroupInfoTabs/missed.dart';

class GrpInfoTabsHome extends StatefulWidget {
  final String peerId;
  // final String peerAvatar;
  final String chatType;
  final String groupName;

  GrpInfoTabsHome(
      {Key key,
      @required this.peerId,
      @required this.chatType,
      @required this.groupName})
      : super(key: key);

  @override
  _GrpInfoTabsHomeState createState() => new _GrpInfoTabsHomeState();
}

class _GrpInfoTabsHomeState extends State<GrpInfoTabsHome>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, initialIndex: 0, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("${widget.groupName}"),
        elevation: 0.7,
        bottom: new TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: <Widget>[
            new Tab(
              child: Text(
                "Active", style: new TextStyle(
                      fontSize: 18.0,
                      fontStyle: FontStyle.normal,
                    ),
              ),
            ),
            new Tab(
               child: Text(
                "Missing", style: new TextStyle(
                      fontSize: 18.0,
                      fontStyle: FontStyle.normal,
                    ),
              ),
            ),
          ],
        ),

        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
               Navigator.of(context).pushNamedAndRemoveUntil(
                        '/homepage', (Route<dynamic> route) => false);
            },
          ),
        ],
        backgroundColor: Color(0xffb00bae3),
      ),
      body: new TabBarView(
        controller: _tabController,
        children: <Widget>[
          new JoinedPage(peerId: widget.peerId),
          new MissedPage(peerId: widget.peerId),
        ],
      ),
    );
  }
}
