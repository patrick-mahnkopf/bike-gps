import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../domain/entities/tour/entities.dart';

class TrackPointModel extends TrackPoint {
  const TrackPointModel(
      {@required LatLng latLng,
      @required double elevation,
      @required double distanceFromStart,
      @required String surface,
      @required bool isWayPoint,
      WayPoint wayPoint})
      : assert(!isWayPoint || (isWayPoint && wayPoint != null)),
        super(
            latLng: latLng,
            elevation: elevation,
            distanceFromStart: distanceFromStart,
            surface: surface,
            isWayPoint: isWayPoint,
            wayPoint: wayPoint);
}
