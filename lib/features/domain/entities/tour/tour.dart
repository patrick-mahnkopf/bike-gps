import 'dart:developer';

import 'package:bike_gps/features/data/models/tour/models.dart';
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
      : highestPoint = trackPoints.first.elevation != null
            ? trackPoints.fold(
                double.negativeInfinity,
                (highest, current) =>
                    current.elevation > highest ? current.elevation : highest)
            : 0;

  TrackPoint trackPointForWayPoint(WayPoint wayPoint) =>
      trackPoints.firstWhere((trackPoint) => trackPoint.wayPoint == wayPoint);

  List<LatLng> get trackPointCoordinateList =>
      trackPoints.map((trackPoint) => trackPoint.latLng).toList();

  void replaceWayPoint(WayPoint currentWayPoint, WayPoint newWayPoint) {
    final TrackPoint currentTrackPoint = trackPointForWayPoint(currentWayPoint);
    final int trackPointIndex = trackPoints.indexOf(currentTrackPoint);
    final int wayPointIndex = wayPoints.indexOf(currentWayPoint);
    trackPoints[trackPointIndex] = TrackPointModel(
        latLng: newWayPoint.latLng,
        elevation: newWayPoint.elevation,
        distanceFromStart: newWayPoint.distanceFromStart,
        surface: newWayPoint.surface,
        isWayPoint: true,
        wayPoint: newWayPoint);
    wayPoints[wayPointIndex] = newWayPoint;
  }

  void addWayPointToTrackPoint(
      TrackPoint trackPoint, WayPoint wayPoint, int i) {
    log('trackPoint: latLng: ${trackPoint.latLng}, i: $i, latLng: ${trackPoints[i].latLng}',
        name: 'Tour addWayPointToTrackPoint');
    final int trackPointIndex = trackPoints.indexOf(trackPoint);
    if (trackPointIndex == 0 || wayPoints.isEmpty) {
      wayPoints.add(wayPoint);
    } else {
      for (var i = trackPointIndex; i < trackPoints.length; i++) {
        final TrackPoint currentTrackPoint = trackPoints[i];
        if (currentTrackPoint.isWayPoint) {
          final int index = wayPoints.indexOf(currentTrackPoint.wayPoint);
          wayPoints.insert(index, wayPoint);
          break;
        }
        if (i == trackPoints.length - 1) {
          wayPoints.add(wayPoint);
        }
      }
    }
    trackPoints[trackPointIndex] = TrackPointModel(
        latLng: wayPoint.latLng,
        elevation: wayPoint.elevation,
        distanceFromStart: wayPoint.distanceFromStart,
        surface: wayPoint.surface,
        isWayPoint: true,
        wayPoint: wayPoint);
  }

  @override
  List<Object> get props =>
      [name, trackPoints, wayPoints, ascent, descent, tourLength, bounds];

  @override
  String toString() =>
      'Tour: { name: $name, ascent: $ascent, descent: $descent, tourLength: $tourLength, bounds: $bounds }';
}
