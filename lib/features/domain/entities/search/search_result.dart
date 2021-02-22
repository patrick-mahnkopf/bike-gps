import 'package:flutter/cupertino.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class SearchResult {
  final String name;
  final String street;
  final String city;
  final String state;
  final String country;
  final LatLng coordinates;
  final bool isTour;

  SearchResult(
      {@required this.name,
      @required this.country,
      @required this.coordinates,
      this.street,
      this.city,
      this.state,
      this.isTour = false})
      : assert(name != null && name != ''),
        assert(country != null && country != ''),
        assert(coordinates != null);

  bool get hasState => state?.isNotEmpty == true;

  bool get hasCountry => country?.isNotEmpty == true;

  bool get hasStreet => street?.isNotEmpty == true;

  bool get hasCity => city?.isNotEmpty == true;

  bool get isCountry => hasCountry && name == country;

  bool get isState => hasState && name == state;

  String get secondaryAddress {
    if (isCountry) return '';
    if (isState) return country;
    if (hasStreet && hasCity) return '$street, $city';
    if (hasCity && hasState) return '$city, $state';
    if (hasCity) return city;
    return state;
  }
}
