import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class SearchResult extends Equatable {
  final String name;
  final String street;
  final String city;
  final String state;
  final String country;
  final LatLng coordinates;
  final bool isTour;

  const SearchResult(
      {@required this.name,
      @required this.country,
      @required this.coordinates,
      this.street,
      this.city,
      this.state,
      this.isTour = false})
      : assert(name != null && name != '' && name != 'null'),
        assert(country != null && country != '' && country != 'null'),
        assert(coordinates != null);

  bool get hasState => state != null && state.isNotEmpty && state != 'null';

  bool get hasCountry =>
      country != null && country.isNotEmpty && country != 'null';

  bool get hasStreet => street != null && street.isNotEmpty && street != 'null';

  bool get hasCity => city != null && city.isNotEmpty && city != 'null';

  bool get isCountry => hasCountry && name == country;

  bool get isState => hasState && name == state;

  String get secondaryAddress {
    if (isCountry) {
      return '';
    }
    if (isState) {
      return country;
    }
    if (hasStreet && hasCity) {
      return '$street, $city';
    }
    if (hasCity && hasState) {
      return '$city, $state';
    }
    if (hasCity) {
      return city;
    }
    if (hasState && hasCountry) {
      return '$state, $country';
    }
    return country;
  }

  @override
  List<Object> get props =>
      [name, street, city, state, country, coordinates, isTour];
}
