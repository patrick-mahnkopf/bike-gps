import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class TourLine extends Equatable {
  final Line background;
  final Line tour;
  final Line touchArea;
  final String tourName;
  final bool isActive;
  final bool isPathToTour;

  const TourLine(
      {@required this.background,
      @required this.tour,
      @required this.touchArea,
      @required this.tourName,
      @required this.isActive,
      @required this.isPathToTour});

  @override
  List<Object> get props => [background, tour, touchArea];
}
