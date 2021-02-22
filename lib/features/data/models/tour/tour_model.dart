import 'package:bike_gps/features/data/models/tour/models.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../domain/entities/tour/entities.dart';

class TourModel extends Tour {
  TourModel({
    @required String name,
    @required List<TrackPointModel> trackPoints,
    @required List<WayPointModel> wayPoints,
    @required double ascent,
    @required double descent,
    @required double tourLength,
    @required LatLngBounds bounds,
  }) : super(
            name: name,
            trackPoints: trackPoints,
            wayPoints: wayPoints,
            bounds: bounds,
            ascent: ascent,
            descent: descent,
            tourLength: tourLength);
}
