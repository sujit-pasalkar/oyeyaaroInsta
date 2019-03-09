import 'package:flutter/material.dart';
import '../../../models/group_model.dart';
import '../../ChatPage/GroupChatPage/chatPage.dart';

class ListViewPosts extends StatelessWidget {
  final List<GroupModel> posts;
  final ScrollController hideButtonController;

  ListViewPosts({Key key, this.posts, @required this.hideButtonController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListView.builder(
        controller: hideButtonController,
          shrinkWrap: true,
          itemCount: posts.length,
          // padding: const EdgeInsets.all(15.0),
          padding: EdgeInsets.fromLTRB(5.0, 0.5, 0.0, 0.2),
          itemBuilder: (context, position) {
            return Column(
              children: <Widget>[
                ListTile(
                  leading: Container(
                    width: 50.0,
                    height: 50.0,
                    margin: EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: Color(0xffb00bae3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 35.0,
                    ),
                  ),
                  // ),
                  title: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(
                        '${posts[position].name}',
                        style: new TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18.0),
                      ),
                    ],
                  ),
                  // subtitle: Text(
                  //   '${posts[position].message}',
                  //   style: new TextStyle(
                  //     fontSize: 18.0,
                  //     fontStyle: FontStyle.italic,
                  //   ),
                  // ),
                  onTap: () => _onTapGroup(context, position),
                ),
                Divider(height: 5.0),
              ],
            );
          }),
    );
  }

  Future<void> _onTapGroup(context, position) async {
    print('Group chat id:******************** ${this.posts[position].ids}');
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chat(
                peerId: this.posts[position].ids,
                chatType: 'group',
                name: this.posts[position].name,
                groupInfo: this.posts,
                adminId:this.posts[position].adminId
              ),
        ));
  }
}
