import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class Place {
  final String name;
  final String street;
  final String city;
  final String state;
  final String country;
  final bool isRoute;
  final LatLng coordinates;

  const Place(
      {@required this.name,
      this.street,
      this.city,
      this.state,
      this.country,
      this.coordinates,
      this.isRoute = false})
      : assert(name != null),
        assert(country != null),
        assert(coordinates != null);

  bool get hasState => state?.isNotEmpty == true;

  bool get hasCountry => country?.isNotEmpty == true;

  bool get hasStreet => street?.isNotEmpty == true;

  bool get hasCity => city?.isNotEmpty == true;

  bool get isCountry => hasCountry && name == country;

  bool get isState => hasState && name == state;

  factory Place.fromJson(Map<String, dynamic> map, {bool isRoute}) {
    final props = map['properties'];
    final coordinates = map['geometry']['coordinates'];

    return Place(
      name: props['name'] ?? '',
      street: props['street'] ?? '',
      city: props['city'] ?? '',
      state: props['state'] ?? '',
      country: props['country'] ?? '',
      coordinates: coordinates[0] == null
          ? LatLng(
              coordinates['1'],
              coordinates['0'],
            )
          : LatLng(
              coordinates[1],
              coordinates[0],
            ),
      isRoute: isRoute ?? false,
    );
  }

  String get address {
    if (isCountry) return country;
    return '$name, $level2Address';
  }

  String get secondaryAddress {
    if (isCountry) return '';
    if (isState) return country;
    if (hasStreet && hasCity) return '$street, $city';
    if (hasCity && hasState) return '$city, $state';
    if (hasCity) return '$city';
    return '$state';
  }

  String get addressShort {
    if (isCountry) return country;
    return '$name, $country';
  }

  String get level2Address {
    if (isCountry || isState || !hasState) return country;
    if (!hasCountry) return state;
    return '$state, $country';
  }

  Map<String, dynamic> toJson() => {
        'properties': {
          'name': name,
          'street': street,
          'city': city,
          'state': state,
          'country': country,
        },
        'geometry': {
          'coordinates': {
            '0': coordinates.longitude,
            '1': coordinates.latitude,
          },
        },
      };

  @override
  String toString() =>
      'Place(name: $name, street: $street, city: $city, state: $state, country: $country, coordinates: $coordinates, isRoute: $isRoute)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Place &&
        o.name == name &&
        o.state == state &&
        o.country == country;
  }

  @override
  int get hashCode => name.hashCode ^ state.hashCode ^ country.hashCode;
}
