import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/domain/entities/search/search_result.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

/// Represents a search result.
class SearchResultModel extends SearchResult {
  const SearchResultModel(
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

  /// Converts the Json [map] to a [SearchResultModel].
  factory SearchResultModel.fromJson(Map<String, dynamic> map,
      {@required TourListHelper tourListHelper}) {
    final props = map['properties'];
    final coordinates = map['geometry']['coordinates'];
    final String name = props['name'].toString();
    final isTour = tourListHelper.contains(name);

    if (name.isEmpty || name == null || name == 'null') {
      return null;
    }

    return SearchResultModel(
      name: name ?? '',
      street: props['street'].toString() ?? '',
      city: props['city'].toString() ?? '',
      state: props['state'].toString() ?? '',
      country: props['country'].toString() ?? '',
      coordinates: LatLng(
        double.parse(coordinates[1].toString()),
        double.parse(coordinates[0].toString()),
      ),
      isTour: isTour ?? false,
    );
  }
}
