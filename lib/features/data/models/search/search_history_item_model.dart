import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:bike_gps/features/domain/entities/search/entities.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

/// Represents an entry of the search history.
class SearchHistoryItemModel extends SearchResultModel {
  const SearchHistoryItemModel(
      {@required String name,
      @required String country,
      @required LatLng coordinates,
      String street,
      String city,
      String state,
      bool isTour = false})
      : assert(name != null && name != ''),
        assert(country != null && country != ''),
        assert(coordinates != null),
        super(
            name: name,
            country: country,
            coordinates: coordinates,
            street: street,
            city: city,
            state: state,
            isTour: isTour);

  /// Converts a [SearchResult] to a [SearchHistoryItemModel].
  factory SearchHistoryItemModel.fromSearchResult(
      {@required SearchResult searchResult}) {
    return SearchHistoryItemModel(
        name: searchResult.name,
        coordinates: searchResult.coordinates,
        country: searchResult.country,
        city: searchResult.city,
        isTour: searchResult.isTour,
        state: searchResult.state,
        street: searchResult.street);
  }

  /// Converts the Json [map] to a [SearchHistoryItemModel].
  factory SearchHistoryItemModel.fromJson(Map<String, dynamic> map,
      {@required TourListHelper tourListHelper}) {
    final properties = map['properties'];
    final coordinates = properties['coordinates'];
    final isTour = tourListHelper.contains(properties['name'].toString());

    return SearchHistoryItemModel(
      name: properties['name'].toString() ?? '',
      street: properties['street'].toString() ?? '',
      city: properties['city'].toString() ?? '',
      state: properties['state'].toString() ?? '',
      country: properties['country'].toString() ?? '',
      coordinates: LatLng(
        double.parse(coordinates['0'].toString()),
        double.parse(coordinates['1'].toString()),
      ),
      isTour: isTour ?? false,
    );
  }

  /// Converts this [SearchHistoryItemModel] to Json.
  Map<String, dynamic> toJson() => {
        'properties': {
          'name': name,
          'street': street,
          'city': city,
          'state': state,
          'country': country,
          'coordinates': {
            '0': coordinates.latitude,
            '1': coordinates.longitude,
          },
        },
      };
}
