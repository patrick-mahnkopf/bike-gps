import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class TourInfoModel extends TourInfo {
  TourInfoModel(
      {@required String name,
      @required LatLngBounds bounds,
      @required String filePath,
      @required String fileHash,
      @required LatLng firstPoint})
      : super(
            name: name,
            bounds: bounds,
            filePath: filePath,
            fileHash: fileHash,
            firstPoint: firstPoint);

  Map<String, dynamic> toJson() => {
        'properties': {
          'name': name,
          'filePath': filePath,
          'fileHash': fileHash,
          'bounds': {
            'southwest': {
              '0': bounds.southwest.latitude,
              '1': bounds.southwest.longitude,
            },
            'northeast': {
              '0': bounds.northeast.latitude,
              '1': bounds.northeast.longitude,
            },
          },
          'firstPoint': {
            '0': firstPoint.latitude,
            '1': firstPoint.longitude,
          },
        },
      };

  factory TourInfoModel.fromJson(
    Map<String, dynamic> map,
  ) {
    final properties = map['properties'];
    final bounds = properties['bounds'];
    final southWestBounds = bounds['southwest'];
    final northEastBounds = bounds['northeast'];
    final firstPoint = properties['firstPoint'];

    return TourInfoModel(
      name: properties['name'].toString() ?? '',
      filePath: properties['filePath'].toString() ?? '',
      fileHash: properties['fileHash'].toString() ?? '',
      bounds: LatLngBounds(
        northeast: LatLng(
          double.parse(northEastBounds['0'].toString()),
          double.parse(northEastBounds['1'].toString()),
        ),
        southwest: LatLng(
          double.parse(southWestBounds['0'].toString()),
          double.parse(southWestBounds['1'].toString()),
        ),
      ),
      firstPoint: LatLng(
        double.parse(firstPoint['0'].toString()),
        double.parse(firstPoint['1'].toString()),
      ),
    );
  }
}
