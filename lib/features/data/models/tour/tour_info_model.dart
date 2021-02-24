import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class TourInfoModel extends TourInfo {
  TourInfoModel(
      {@required String name,
      @required LatLngBounds bounds,
      @required String filePath,
      @required String fileHash,
      @required LatLng firstPoint})
      : super(
            name: name,
            bounds: bounds,
            filePath: filePath,
            fileHash: fileHash,
            firstPoint: firstPoint);
}
