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
        '<gpx version="1.1" creator="Bike GPS" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');
    _writeGpxMetadataToBuffer(sb);
    _writeGpxTrackDataToBuffer(sb);
    sb.write('</gpx>');
    return sb.toString();
  }

  void _writeGpxMetadataToBuffer(StringBuffer sb) {
    final DateTime dateTime = DateTime.now();
    _writeIndentation(sb, 1);
    sb.writeln('<metadata>');
    _writeIndentation(sb, 2);
    sb.writeln('<name>Bike GPS Exported GPX</name>');
    _writeIndentation(sb, 2);
    sb.writeln('<desc></desc>');
    _writeIndentation(sb, 2);
    sb.writeln('<time>$dateTime</time>');
    _writeIndentation(sb, 2);
    sb.writeln(
        '<bounds minlat="${bounds.southwest.latitude}" minlon="${bounds.southwest.longitude}" maxlat="${bounds.northeast.latitude}" maxlon="${bounds.northeast.longitude}"/>');
    _writeIndentation(sb, 1);
    sb.writeln('</metadata>');
  }

  void _writeGpxTrackDataToBuffer(StringBuffer sb) {
    _writeIndentation(sb, 1);
    sb.writeln('<trk>');
    _writeIndentation(sb, 2);
    sb.writeln('<name>$name</name>');
    _writeIndentation(sb, 2);
    sb.writeln('<trkseg>');
    for (final TrackPoint trackPoint in trackPoints) {
      _writeIndentation(sb, 3);
      sb.writeln(
          '<trkpt lat="${trackPoint.latLng.latitude}" lon="${trackPoint.latLng.longitude}">');
      _writeIndentation(sb, 4);
      sb.writeln('<ele>${trackPoint.elevation}</ele>');
      if (trackPoint.isWayPoint) {
        final WayPoint wayPoint = trackPoint.wayPoint;
        _writeIndentation(sb, 4);
        sb.writeln('<name>${wayPoint.name}</name>');
        _writeIndentation(sb, 4);
        sb.writeln('<extensions>');
        _writeIndentation(sb, 5);
        sb.writeln('<location>${wayPoint.location}</location>');
        _writeIndentation(sb, 5);
        sb.writeln('<direction>${wayPoint.direction}</direction>');
        _writeIndentation(sb, 5);
        sb.writeln('<surface>${wayPoint.surface}</surface>');
        _writeIndentation(sb, 5);
        sb.writeln('<turnsymbolid>${wayPoint.turnSymboldId}</turnsymbolid>');
        _writeIndentation(sb, 4);
        sb.writeln('</extensions>');
      }
      _writeIndentation(sb, 3);
      sb.writeln('</trkpt>');
    }
    _writeIndentation(sb, 2);
    sb.writeln('</trkseg>');
    _writeIndentation(sb, 1);
    sb.writeln('</trk>');
  }

  void _writeIndentation(StringBuffer sb, int indentLevel) {
    const String indentation = '    ';
    for (int i = 0; i < indentLevel; i++) {
      sb.write(indentation);
    }
  }
}
