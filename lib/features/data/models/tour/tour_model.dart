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

  String toGpx() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln(
        '<gpx xmlns="http://www.topografix.com/GPX/1/1" version="1.1" creator="Bike GPS" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');
    _writeGpxMetadataToBuffer(sb);
    _writeGpxTrackDataToBuffer(sb);
    sb.write('</gpx>');
    return sb.toString();
  }

  void _writeGpxMetadataToBuffer(StringBuffer sb) {
    final DateTime dateTime = DateTime.now();
    sb.writeln('<metadata>');
    sb.writeln('<name>Bike GPS Exported GPX</name>');
    sb.writeln('<desc></desc>');
    sb.writeln('<time>$dateTime</time>');
    sb.writeln(
        '<bounds minlat="${bounds.southwest.latitude}" minlon="${bounds.southwest.longitude}" maxlat="${bounds.northeast.latitude}" maxlon="${bounds.northeast.longitude}"/>');
    sb.writeln('</metadata>');
  }

  void _writeGpxTrackDataToBuffer(StringBuffer sb) {
    sb.writeln('<trk>');
    sb.writeln('<name>$name</name>');
    sb.writeln('<trkseg>');
    for (final TrackPoint trackPoint in trackPoints) {
      sb.writeln(
          '<trkpt lat="${trackPoint.latLng.latitude}" lon="${trackPoint.latLng.longitude}">');
      sb.writeln('<ele>${trackPoint.elevation}</ele>');
      if (trackPoint.isWayPoint) {
        final WayPoint wayPoint = trackPoint.wayPoint;
        sb.writeln('<name>${wayPoint.name}</name>');
        sb.writeln('<trkpt>');
        sb.writeln('<location>${wayPoint.location}</location>');
        sb.writeln('<direction>${wayPoint.direction}</direction>');
        sb.writeln('<surface>${wayPoint.surface}</surface>');
        sb.writeln('<turnsymbolid>${wayPoint.turnSymboldId}</turnsymbolid>');
        sb.writeln('</trkpt>');
      }
      sb.writeln('</trkpt>');
    }
    sb.writeln('</trkseg>');
    sb.writeln('</trk>');
  }
}
