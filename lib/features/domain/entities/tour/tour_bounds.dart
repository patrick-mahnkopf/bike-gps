import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

/// Represents the a tour's bounds
class TourBounds {
  final String name;
  LatLngBounds bounds;

  TourBounds({@required this.bounds, @required this.name});

  double get west => bounds.southwest.longitude;

  set west(double newValue) => bounds = LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude, newValue),
      northeast: bounds.northeast);

  double get east => bounds.northeast.longitude;

  set east(double newValue) => bounds = LatLngBounds(
      southwest: bounds.southwest,
      northeast: LatLng(bounds.northeast.latitude, newValue));

  double get north => bounds.northeast.latitude;

  set north(double newValue) => bounds = LatLngBounds(
      southwest: bounds.southwest,
      northeast: LatLng(newValue, bounds.northeast.longitude));

  double get south => bounds.southwest.latitude;

  set south(double newValue) => bounds = LatLngBounds(
      southwest: LatLng(newValue, bounds.southwest.longitude),
      northeast: bounds.northeast);

  double get area => (east - west) * (north - south);

  /// Calculates the overlap of this [TourBounds] [bounds] with that of [other].
  ///
  /// Returns the overlap percentage of the two tour bounds.
  double getOverlap(TourBounds other) {
    if (east <= other.west ||
        other.east <= west ||
        north <= other.south ||
        other.north <= south) return 0;
    final double overlapArea = (min(east, other.east) - max(west, other.west)) *
        (min(north, other.north) - max(south, other.south));
    return max(0, overlapArea / (area + other.area - overlapArea));
  }

  LatLngBounds get toLatLngBounds => bounds;
}
