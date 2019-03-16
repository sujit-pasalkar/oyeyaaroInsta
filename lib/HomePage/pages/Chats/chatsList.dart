import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../HomePage/ChatPage/PrivateChatPage/privateChatePage.dart';
import '../../../ProfilePage/profile.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListViewPosts extends StatelessWidget {
  final ScrollController hideButtonController;
  final List<ChatModel> posts;

  // String avatarUrl = "http://54.200.143.85:4200/profiles/now/";
  ListViewPosts({Key key, this.posts, @required this.hideButtonController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
          controller: hideButtonController,
          itemCount: posts.length,
          padding: EdgeInsets.fromLTRB(0.0, 0.1, 0.0, 0.1),
          itemBuilder: (context, position) {
            return Column(
              children: <Widget>[
                ListTile(
                    leading: GestureDetector(
                        child: Container(
                          width: 65.0,
                          height: 65.0,
                          decoration: BoxDecoration(
                            color: Color(0xffb00bae3),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child:
                            Container(
                                margin: EdgeInsets.all(1.0),
                                decoration: new BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40.0),
                                  child: CachedNetworkImage(
                                    imageUrl:'http://54.200.143.85:4200/getAvatarImageNow/${posts[position].receiverPin}',
                                    fit: BoxFit.cover,
                                    placeholder: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: SizedBox(
                                        child: CircularProgressIndicator(
                                            valueColor:
                                                new AlwaysStoppedAnimation<
                                                    Color>(Color(0xffb00bae3)),
                                            strokeWidth: 1.0),
                                      ),
                                    ),
                                    errorWidget: new Icon(
                                      Icons.error,
                                      color: Colors.black,
                                    ),
                                  ),
                                )),
                            //  Container(
                            //   margin: EdgeInsets.all(2.0),
                            //   decoration: BoxDecoration(
                            //     color: Colors.white,
                            //     shape: BoxShape.circle,
                            //     image: DecorationImage(
                            //       fit: BoxFit.cover,
                            //       image:
                            //           // posts[position].isNowImg
                            //           //     ?
                            //            NetworkImage( 'http://54.200.143.85:4200/getAvatarImageNow/${posts[position].receiverPin}'
                            //           //         "http://54.200.143.85:4200/profiles/now/${posts[position].receiverPin}.jpg"
                            //           )
                            //           //     : NetworkImage(
                            //           //         "http://54.200.143.85:4200/profiles/then/${posts[position].receiverPin}.jpg"),
                            //     ),
                            //   ),
                            // ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                      userPin: posts[position].receiverPin)));
                        }),
                    subtitle: Text(
                      '${this.posts[position].senderGroup[0]}',
                      style: new TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    title: GestureDetector(
                      child: new Text(
                        '${posts[position].receiverName[0].toUpperCase()}${posts[position].receiverName.substring(1)}',
                        style: new TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    onTap: () => _onTapChatUser(context, position)),
                Divider(height: 5.0),
              ],
            );
          }),
    );
  }

  Future<void> _onTapChatUser(context, position) async {
    print("****" + this.posts[position].chat_id);
    print(this.posts[position].receiverName);
    print(this.posts[position].receiverPin);
    print('group array : ${this.posts[position].senderGroup}');

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPrivate(
              chatId: this.posts[position].chat_id,
              chatType: 'private',
              name: this.posts[position].receiverName,
              receiverPin: this.posts[position].receiverPin,
              mobile: this.posts[position].receiverPhone),
        ));
  }
}
