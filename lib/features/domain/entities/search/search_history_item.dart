import 'package:bike_gps/features/domain/entities/search/search_result.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class SearchHistoryItem extends SearchResult {
  SearchHistoryItem(
      {@required String name,
      @required String country,
      @required LatLng coordinates,
      String city,
      bool isTour = false,
      String state,
      String street})
      : super(
            name: name,
            coordinates: coordinates,
            country: country,
            city: city,
            isTour: isTour,
            state: state,
            street: street);
}
