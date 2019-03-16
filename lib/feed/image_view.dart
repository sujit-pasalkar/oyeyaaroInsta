import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer extends StatelessWidget {
  final String imageUrl;

  ImageViewer({@required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: PhotoView(
          heroTag: imageUrl,
          imageProvider: NetworkImage(imageUrl),
          //CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained * 1,
          maxScale: 4.0,
        ),
      ),
    );
  }
}
