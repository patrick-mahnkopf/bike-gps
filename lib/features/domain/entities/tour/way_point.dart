import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'entities.dart';

class WayPoint extends TrackPoint {
  final String direction;
  final String location;
  final String name;
  final String turnSymboldId;

  const WayPoint(
      {@required LatLng latLng,
      @required double elevation,
      @required double distanceFromStart,
      @required String surface,
      @required this.name,
      @required this.location,
      @required this.direction,
      @required this.turnSymboldId})
      : super(
          latLng: latLng,
          elevation: elevation,
          distanceFromStart: distanceFromStart,
          surface: surface,
          isWayPoint: false,
        );

  @override
  List<Object> get props => [
        latLng,
        elevation,
        distanceFromStart,
        surface,
        isWayPoint,
        name,
        location,
        direction,
        turnSymboldId
      ];
}
