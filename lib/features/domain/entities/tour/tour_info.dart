import 'package:flutter/cupertino.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class TourInfo {
  final String name;
  final LatLngBounds bounds;
  final String filePath;
  final String fileHash;
  final LatLng firstPoint;

  TourInfo(
      {@required this.name,
      @required this.bounds,
      @required this.filePath,
      @required this.fileHash,
      @required this.firstPoint});
}
