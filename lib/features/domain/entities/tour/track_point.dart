import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'entities.dart';

class TrackPoint extends Equatable {
  final double distanceFromStart;
  final double elevation;
  final bool isWayPoint;
  final LatLng latLng;
  final String surface;
  final WayPoint wayPoint;

  const TrackPoint(
      {@required this.latLng,
      @required this.elevation,
      @required this.distanceFromStart,
      @required this.surface,
      @required this.isWayPoint,
      this.wayPoint})
      : assert(!isWayPoint || (isWayPoint && wayPoint != null));

  @override
  List<Object> get props =>
      [latLng, elevation, distanceFromStart, surface, isWayPoint];

  @override
  String toString() =>
      'TrackPoint: { latLng: $latLng, elevation: $elevation, distanceFromStart: $distanceFromStart, surface: $surface, isWayPoint: $isWayPoint }';
}
