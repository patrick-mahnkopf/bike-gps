import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../core/error/exception.dart';
import '../../models/tour/models.dart';
import '../tour_parser/data_sources.dart';

abstract class TourRemoteDataSource {
  Future<TourModel> getPathToTour(
      {@required LatLng userLocation, @required LatLng tourStart});
}

@Injectable(as: TourRemoteDataSource)
class TourRemoteDataSourceImpl implements TourRemoteDataSource {
  final Client client;
  final TourParser tourParser;

  TourRemoteDataSourceImpl({@required this.tourParser, @required this.client});

  /// Calls the route service endpoint found in 'assets/token/route_service_url.txt'.
  ///
  /// Throws a [ServerException] for all error codes.
  @override
  Future<TourModel> getPathToTour(
      {@required LatLng userLocation, @required LatLng tourStart}) async {
    final String tourFileContent = await _getTourFileContentFromRouteService(
        userLocation: userLocation, tourStart: tourStart);
    return tourParser.getTourFromFileContent(
        tourFileContent: tourFileContent, tourName: 'ORS', filePath: '');
  }

  Future<String> _getTourFileContentFromRouteService(
      {@required LatLng userLocation, @required LatLng tourStart}) async {
    final String baseUrl =
        await rootBundle.loadString('assets/tokens/route_service_url.txt');
    final Response response = await client.post(
      baseUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept':
            'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
      },
      body: jsonEncode(<String, dynamic>{
        'coordinates': [
          [userLocation.longitude, userLocation.latitude],
          [tourStart.longitude, tourStart.latitude]
        ],
        'extra_info': [
          'surface',
          'waycategory',
          'waytype',
          'traildifficulty',
        ],
        'instructions': 'true',
        'instructions_format': 'text',
      }),
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ServerException();
    }
  }
}
