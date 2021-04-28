import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

/// Represents a tour line as drawn on the Mapbox map.
///
/// A tour line consists of three lines. The actual [tour] line, a [background]
/// line, and a [touchArea] line.
class TourLine extends Equatable {
  final Line background;
  final Line tour;
  final Line touchArea;
  final String tourName;
  final bool isActive;
  final bool isPathToTour;
  final List<Symbol> directionArrows;

  const TourLine(
      {@required this.background,
      @required this.tour,
      @required this.touchArea,
      @required this.tourName,
      @required this.isActive,
      @required this.isPathToTour,
      this.directionArrows});

  @override
  List<Object> get props => [background, tour, touchArea];
}
