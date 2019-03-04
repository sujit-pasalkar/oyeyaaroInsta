import 'package:flutter/material.dart';
import 'package:connect_yaar/models/data-service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class S3Image extends StatefulWidget {
  final AlignmentGeometry alignment;
  final Rect centerSlice;
  final Color color;
  final BlendMode colorBlendMode;
  final bool excludeFromSemantics;
  final String filename;
  final FilterQuality filterQuality;
  final BoxFit fit;
  final bool gaplessPlayback;
  final double height;
  final Key key;
  final bool matchTextDirection;
  final Widget placeholder;
  final ImageRepeat repeat;
  final String semanticLabel;
  final double width;

  S3Image({
    @required this.filename,
    this.alignment,
    this.centerSlice,
    this.color,
    this.colorBlendMode,
    this.excludeFromSemantics,
    this.filterQuality,
    this.fit,
    this.gaplessPlayback,
    this.height,
    this.key,
    this.matchTextDirection,
    this.placeholder,
    this.repeat,
    this.semanticLabel,
    this.width,
  });

  _S3Image createState() => _S3Image();
}

class _S3Image extends State<S3Image> {
  bool downloading;
  File file;
  Image s3image;

  @override
  initState() {
    downloading = true;
    _getImage();
    super.initState();
  }

  @override
  dispose() {
    file = null;
    s3image = null;
    super.dispose();
  }

  _getImage() async {
    Directory extDir = await getExternalStorageDirectory();
    File downloadedFile = File(
        extDir.path + "/OyeYaaro/Media/" + widget.filename.split("/").last);
    bool fileExist = await downloadedFile.exists();

    if (fileExist) {
      file = downloadedFile;
    } else {
      file =
          await dataService.downloadFileFromS3(widget.filename.split("/").last);
    }

    s3image = Image(
      alignment: widget.alignment != null ? widget.alignment : Alignment.center,
      centerSlice: widget.centerSlice,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      excludeFromSemantics: widget.excludeFromSemantics != null
          ? widget.excludeFromSemantics
          : false,
      filterQuality: widget.filterQuality != null
          ? widget.filterQuality
          : FilterQuality.low,
      fit: widget.fit,
      gaplessPlayback:
          widget.gaplessPlayback != null ? widget.gaplessPlayback : false,
      height: widget.height,
      image: FileImage(file),
      key: widget.key,
      matchTextDirection:
          widget.matchTextDirection != null ? widget.matchTextDirection : false,
      repeat: widget.repeat != null ? widget.repeat : ImageRepeat.noRepeat,
      semanticLabel: widget.semanticLabel,
      width: widget.width,
    );

    setState(() {
      downloading = false;
    });
  }

  Widget build(BuildContext context) {
    return downloading
        ? widget.placeholder == null ? Container() : widget.placeholder
        : s3image;
  }
}