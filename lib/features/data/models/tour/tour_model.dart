import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../domain/entities/tour/entities.dart';

class TourModel extends Tour {
  TourModel({
    @required String name,
    @required String filePath,
    @required List<TrackPoint> trackPoints,
    @required List<WayPoint> wayPoints,
    @required double ascent,
    @required double descent,
    @required double tourLength,
    @required LatLngBounds bounds,
  }) : super(
            name: name,
            filePath: filePath,
            trackPoints: trackPoints,
            wayPoints: wayPoints,
            bounds: bounds,
            ascent: ascent,
            descent: descent,
            tourLength: tourLength);
}
