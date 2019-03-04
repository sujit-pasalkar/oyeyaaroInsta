import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "dart:async";
import '../models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Comments extends StatefulWidget {
  final String postId;
  final String postOwner;
  final String postMediaUrl;

  Comments({this.postId, this.postOwner, this.postMediaUrl});

  @override
  _CommentsState createState() => _CommentsState(
      postId: this.postId,
      postOwner: this.postOwner,
      postMediaUrl: this.postMediaUrl);
}

class _CommentsState extends State<Comments> {
  final String postId;
  final String postOwner;
  final String postMediaUrl;

  final TextEditingController _commentController = TextEditingController();

  _CommentsState({this.postId, this.postOwner, this.postMediaUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Comments",
        ),
        backgroundColor: Color(0xffb00bae3),
      ),
      body: buildPage(),
    );
  }

  Widget buildPage() {
    return Column(
      children: [
        Expanded(
          child: buildComments(),
        ),
        Container(
          decoration: BoxDecoration(
            color: Color(0xffb00bae3),
            border: Border(
                top: BorderSide(
              color: Color(0xffb00bae3),
              width: 2.5,
            )),
          ),
          child: TextFormField(
            controller: _commentController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              labelText: 'Write a comment...',
              labelStyle: TextStyle(
                color: Colors.white70,
              ),
              suffixIcon: IconButton(
                color: Colors.white,
                disabledColor: Colors.white70,
                icon: Icon(Icons.send),
                onPressed: _commentController.text.isEmpty
                    ? null
                    : () {
                        addComment(_commentController.text);
                      },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildComments() {
    return FutureBuilder<List<Comment>>(
        future: getComments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                child: CircularProgressIndicator());

          return ListView(
            children: snapshot.data,
          );
        });
  }

  Future<List<Comment>> getComments() async {
    List<Comment> comments = [];

    QuerySnapshot data = await Firestore.instance
        .collection("insta_comments")
        .document(postId)
        .collection("comments")
        .getDocuments();
    data.documents.forEach((DocumentSnapshot doc) {
      comments.add(Comment.fromDocument(doc));
    });

    return comments;
  }

  addComment(String comment) {
    _commentController.clear();
    Firestore.instance
        .collection("insta_comments")
        .document(postId)
        .collection("comments")
        .add({
      "username": currentUser.username,
      "comment": comment,
      "timestamp": DateTime.now().toString(),
      "avatarUrl": currentUser.photoURL,
      "userId": currentUser.userId
    });

    //adds to postOwner's activity feed
    Firestore.instance
        .collection("insta_a_feed")
        .document(postOwner)
        .collection("items")
        .add({
      "username": currentUser.username,
      "userId": currentUser.userId,
      "type": "comment",
      "userProfileImg": currentUser.photoURL,
      "commentData": comment,
      "timestamp": DateTime.now().toString(),
      "postId": postId,
      "mediaUrl": postMediaUrl,
    });
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final String timestamp;

  Comment(
      {this.username,
      this.userId,
      this.avatarUrl,
      this.comment,
      this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot document) {
    return Comment(
      username: document['username'],
      userId: document['userId'],
      comment: document["comment"],
      timestamp: document["timestamp"],
      avatarUrl: document["avatarUrl"],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
          child: Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(avatarUrl),
                radius: 20.0,
              ),
              Container(
                padding: EdgeInsets.only(left: 50.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Text(comment),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(),
      ],
    );
  }
}
