import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'entities.dart';

class Tour extends Equatable {
  final double ascent;
  final LatLngBounds bounds;
  final double descent;
  final double highestPoint;
  final String name;
  final double tourLength;
  final List<TrackPoint> trackPoints;
  final List<WayPoint> wayPoints;

  Tour(
      {@required this.name,
      @required this.trackPoints,
      @required this.wayPoints,
      @required this.ascent,
      @required this.descent,
      @required this.tourLength,
      @required this.bounds})
      : highestPoint = trackPoints.fold(
            double.negativeInfinity,
            (highest, current) =>
                current.elevation > highest ? current.elevation : highest);

  @override
  List<Object> get props =>
      [name, trackPoints, wayPoints, ascent, descent, tourLength, bounds];

  @override
  String toString() =>
      'Tour: { name: $name, ascent: $ascent, descent: $descent, tourLength: $tourLength, bounds: $bounds }';
}
