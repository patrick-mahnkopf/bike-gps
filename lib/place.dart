import 'package:flutter/material.dart';

class Place {
  final String name;
  final String state;
  final String country;
  final bool isRoute;

  const Place(
      {@required this.name, this.state, this.country, this.isRoute = false})
      : assert(name != null),
        assert(country != null || isRoute);

  bool get hasState => state?.isNotEmpty == true;

  bool get hasCountry => country?.isNotEmpty == true;

  bool get isCountry => hasCountry && name == country;

  bool get isState => hasState && name == state;

  factory Place.fromJson(Map<String, dynamic> map) {
    final props = map['properties'];

    return Place(
      name: props['name'] ?? '',
      state: props['state'] ?? '',
      country: props['country'] ?? '',
    );
  }

  String get address {
    if (isCountry) return country;
    return '$name, $level2Address';
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

  @override
  String toString() => 'Place(name: $name, state: $state, country: $country)';

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
