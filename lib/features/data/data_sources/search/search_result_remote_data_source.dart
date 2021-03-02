import 'dart:convert';

import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_tour.dart';
import 'package:bike_gps/injection_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

abstract class SearchResultRemoteDataSource {
  Future<List<SearchResultModel>> getSearchResults({@required String query});
}

@preResolve
@Injectable(as: SearchResultRemoteDataSource)
class SearchResultRemoteDataSourceImpl implements SearchResultRemoteDataSource {
  final TourListHelper tourListHelper;
  final GetTour getTour;

  SearchResultRemoteDataSourceImpl(
      {@required this.tourListHelper, @required this.getTour});

  @override
  Future<List<SearchResultModel>> getSearchResults({String query}) async {
    final response = await http.get('https://photon.komoot.io/api/?q=$query');
    final body = json.decode(utf8.decode(response.bodyBytes));
    final features = body['features'] as List;

    final List<SearchResultModel> searchResults = features
        .map((searchResult) => SearchResultModel.fromJson(
            searchResult as Map<String, dynamic>,
            tourListHelper: getIt()))
        .toSet()
        .toList();

    final List<TourInfo> tourInfos = tourListHelper.asList;
    tourInfos.retainWhere((tourInfo) {
      final String tourName = tourInfo.name;
      if (query.length >= (tourName.length / 3)) {
        return tourName.toLowerCase().contains(query.toLowerCase());
      } else {
        return false;
      }
    });

    for (final TourInfo tourInfo in tourInfos) {
      final SearchResultModel searchResult =
          await _getSearchResultModelFromTourInfo(tourInfo);
      searchResults.insert(0, searchResult);
    }

    return searchResults;
  }

  Future<SearchResultModel> _getSearchResultModelFromTourInfo(
      TourInfo tourInfo) async {
    final Coordinates tourStartCoordinates = Coordinates(
        tourInfo.firstPoint.latitude, tourInfo.firstPoint.longitude);
    final Address address = (await Geocoder.local
            .findAddressesFromCoordinates(tourStartCoordinates))
        .first;

    return SearchResultModel(
        name: tourInfo.name,
        street: address.addressLine.split(',').first,
        city: address.locality,
        coordinates: tourInfo.firstPoint,
        state: address.adminArea,
        country: address.countryName,
        isTour: true);
  }
}
