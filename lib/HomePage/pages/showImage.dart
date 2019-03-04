import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ShowImage extends StatefulWidget {
  String url;
  ShowImage({
    Key key,
    this.url,
  }) : super(key: key);

  @override
  _ShowImageState createState() => _ShowImageState();
}

class _ShowImageState extends State<ShowImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: new Container(
          child: new PhotoView(
            imageProvider: NetworkImage(widget.url),
            minScale: PhotoViewComputedScale.contained * 1,
            maxScale: 4.0,
          ),
        ),
      ),
    );
  }
}