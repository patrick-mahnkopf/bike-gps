import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../domain/entities/tour/entities.dart';

class WayPointModel extends WayPoint {
  const WayPointModel(
      {@required LatLng latLng,
      @required double elevation,
      @required double distanceFromStart,
      @required String surface,
      @required String name,
      @required String location,
      @required String direction,
      @required String turnSymboldId})
      : super(
            latLng: latLng,
            elevation: elevation,
            distanceFromStart: distanceFromStart,
            surface: surface,
            name: name,
            location: location,
            direction: direction,
            turnSymboldId: turnSymboldId);
}
