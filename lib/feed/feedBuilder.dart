import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../models/user.dart';
import '../ProfilePage/profile.dart';
import 'image_view.dart';
import 'comments.dart';
import 'package:flutter/services.dart';
import 'playVideo.dart';
import '../component/image.dart';

class FeedBuilder extends StatefulWidget {
  final String username;
  // final String location;
  final String description;
  final String mediaUrl;
  final String postId;
  final String ownerId;
  final int timestamp;
  final likes;

  FeedBuilder(
      {this.username,
      // this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.postId,
      this.ownerId,
      this.timestamp})
      : super(key: UniqueKey());

  factory FeedBuilder.fromJSON(Map data) {
    return FeedBuilder(
      username: data['username'],
      // location: data['location'],
      description: data['description'],
      mediaUrl: data['mediaUrl'],
      likes: data['likes'],
      ownerId: data['ownerId'],
      postId: data['postId'],
      timestamp: data['timestamp'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    var vals = likes.values;
    int count = 0;
    for (var val in vals) {
      if (val == true) {
        count = count + 1;
      }
    }

    return count;
  }

  _FeedBuilder createState() => _FeedBuilder(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        // location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        timestamp: this.timestamp,
        likeCount: this.getLikeCount(this.likes),
      );
}

class _FeedBuilder extends State<FeedBuilder> {
  final String mediaUrl;
  final String username;
  // final String location;
  final String description;
  final String postId;
  final String ownerId;
  final int timestamp;
  String time;
  Map likes;
  int likeCount;

  String avatarUrl;

  bool liked;
  bool showHeart = false;

  CollectionReference reference = Firestore.instance.collection('insta_posts');

  _FeedBuilder({
    this.postId,
    this.ownerId,
    this.username,
    // this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
    this.timestamp,
  });

  @override
  void initState() {
    avatarUrl = "http://54.200.143.85:4200/profiles/now/$ownerId.jpg";
    time = _calculateTime();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  buildPostHeader() {
    return ListTile(
      leading: InkWell(
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            avatarUrl,
            errorListener: () {
              setState(() {
                avatarUrl = avatarUrl.replaceAll('now', 'then');
              });
            },
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                    userPin: ownerId,
                  ),
            ),
          );
        },
      ),
      title: Text(username),
      subtitle: Text("Somehere on earth"),
      // subtitle: Text("in $location"),
      trailing: _menuBuilder(),
    );
  }

  buildLikeableImge() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        mediaUrl.contains(".png")
            ? GestureDetector(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Hero(
                    tag: mediaUrl,
                    // child: CachedNetworkImage(
                    //   imageUrl: mediaUrl,
                    //   fit: BoxFit.cover,
                    //   placeholder: Image(
                    //     image: AssetImage("assets/loading.gif"),
                    //   ),
                    //   errorWidget: Icon(Icons.error),
                    // ),
                    child: S3Image(
                      filename: mediaUrl,
                      placeholder: Image(
                        image: AssetImage("assets/loading.gif"),
                      ),
                    ),
                  ),
                ),
                onTap: _showImage,
                onDoubleTap: _likePost,
              )
            : GestureDetector(
                child: Stack(
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 1,
                      // child: CachedNetworkImage(
                      //   imageUrl: mediaUrl.replaceFirst(".mp4", ".png"),
                      //   fit: BoxFit.cover,
                      //   placeholder: Image(
                      //     image: AssetImage("assets/loading.gif"),
                      //   ),
                      //   errorWidget: Icon(Icons.error),
                      // ),
                      child: S3Image(
                        filename: mediaUrl.replaceFirst(".mp4", ".png"),
                        placeholder: Image(
                          image: AssetImage("assets/loading.gif"),
                        ),
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.play_arrow,
                            color: Colors.white70,
                          ),
                          iconSize: 100.0,
                          onPressed: () => showVideo(),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: showVideo,
                onDoubleTap: _likePost,
              ),
        showHeart
            ? Positioned(
                child: Opacity(
                  opacity: 0.90,
                  child: Icon(
                    Icons.favorite,
                    size: 80.0,
                    color: Colors.white,
                  ),
                ),
              )
            : SizedBox(
                width: 0.0,
                height: 0.0,
              ),
      ],
    );
  }

  _likePost() async {
    String userId = currentUser.userId;

    bool _liked = likes[userId] == true;

    if (_liked) {
      await reference.document(postId).updateData({
        'likes.$userId': false,
      });

      setState(() {
        likeCount = likeCount - 1;
        liked = false;
        likes[userId] = false;
      });
      removeActivityFeedItem();
    } else if (!_liked) {
      await reference.document(postId).updateData({'likes.$userId': true});
      addActivityFeedItem();
      setState(() {
        likeCount = likeCount + 1;
        liked = true;
        likes[userId] = true;
        showHeart = true;
      });
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addActivityFeedItem() {
    String userId = currentUser.userId;
    String username = currentUser.username;
    String photoUrl = currentUser.photoURL;
    Firestore.instance
        .collection("insta_a_feed")
        .document(ownerId)
        .collection("items")
        .document(postId)
        .setData({
      "username": username,
      "userId": userId,
      "type": "like",
      "userProfileImg": photoUrl,
      "mediaUrl": mediaUrl,
      "timestamp": DateTime.now().toString(),
      "postId": postId,
    });
  }

  removeActivityFeedItem() {
    Firestore.instance
        .collection("insta_a_feed")
        .document(ownerId)
        .collection("items")
        .document(postId)
        .delete();
  }

  _showImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
              imageUrl: mediaUrl,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    liked = (likes[currentUser.userId] == true);
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildPostHeader(),
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
            child: Text(description),
          ),
          SizedBox(
            height: 0.5,
            child: Container(
              color: Colors.grey.shade500,
            ),
          ),
          buildLikeableImge(),
          SizedBox(
            height: 0.5,
            child: Container(
              color: Colors.grey.shade500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 5.0,
              right: 5.0,
              bottom: 10.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : Colors.black,
                  ),
                  onPressed: _likePost,
                ),
                Text(
                  "$likeCount likes",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                SizedBox(
                  width: 15.0,
                ),
                InkWell(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.comment,
                        color: Colors.blue.shade500,
                      ),
                      SizedBox(
                        width: 5.0,
                      ),
                      Text(
                        "Comments",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    goToComments(
                      context: context,
                      postId: postId,
                      ownerId: ownerId,
                      mediaUrl: mediaUrl,
                    );
                  },
                ),
                Spacer(),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 5.0,
            child: Container(
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuBuilder() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey,
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
                    Text("View Profile"),
                    Spacer(),
                    Icon(Icons.person),
                  ],
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'Copy',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  children: <Widget>[
                    Text("Copy Link"),
                    Spacer(),
                    Icon(Icons.content_copy),
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
                  userPin: ownerId,
                ),
          ),
        );
        break;
      case 'Copy':
        Clipboard.setData(ClipboardData(text: mediaUrl));
        break;
    }
  }

  showVideo() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return PlayVideo(
            mediaUrl: mediaUrl,
          );
        },
      ),
    );
  }

  String _calculateTime() {
    int now = (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).ceil();
    int differenceInSeconds = now - timestamp;
    if (differenceInSeconds < 10) {
      return 'Few seconds ago';
    } else if (differenceInSeconds < 59) {
      return differenceInSeconds.toString() + ' seconds ago';
    } else if (differenceInSeconds < 3599) {
      return (differenceInSeconds / 60).floor().toString() + ' minutes ago';
    } else if (differenceInSeconds < 86399) {
      return (differenceInSeconds / 3600).floor().toString() + ' hours ago';
    } else if (differenceInSeconds > 86399 && differenceInSeconds < 31535999) {
      return (differenceInSeconds / 86400).floor().toString() + ' days ago';
    }
    return (differenceInSeconds / 31536000).floor().toString() + ' years ago';
  }
}

goToComments(
    {BuildContext context, String postId, String ownerId, String mediaUrl}) {
  Navigator.of(context).push(
    MaterialPageRoute<bool>(
      builder: (BuildContext context) {
        return Comments(
          postId: postId,
          postOwner: ownerId,
          postMediaUrl: mediaUrl,
        );
      },
    ),
  );
}