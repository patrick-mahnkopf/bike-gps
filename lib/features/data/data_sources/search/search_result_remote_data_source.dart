import 'dart:convert';

import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_tour.dart';
import 'package:bike_gps/injection_container.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

abstract class SearchResultRemoteDataSource {
  Future<List<SearchResultModel>> getSearchResults({@required String query});
}

@Injectable(as: SearchResultRemoteDataSource)
class SearchResultRemoteDataSourceImpl implements SearchResultRemoteDataSource {
  final TourListHelper tourListHelper;
  final GetTour getTour;

  SearchResultRemoteDataSourceImpl(
      {@required this.tourListHelper, @required this.getTour});

  @override
  Future<List<SearchResultModel>> getSearchResults({String query}) async {
    final List<SearchResultModel> searchResults = [];
    final List<TourInfo> tourInfos = tourListHelper.asList;

    final Tuple2<bool, String> isTourQueryAndSanitizedQuery =
        _getIsTourQueryAndSanitizedQuery(query);
    final bool isTourQuery = isTourQueryAndSanitizedQuery.value1;
    final String sanitizedQuery = isTourQueryAndSanitizedQuery.value2;

    for (final TourInfo tourInfo in tourInfos) {
      final String tourName = tourInfo.name.toLowerCase();
      if (tourName.contains(sanitizedQuery)) {
        final SearchResultModel searchResult =
            await _getSearchResultModelFromTourInfo(tourInfo);
        searchResults.add(searchResult);
      }
    }

    if (!isTourQuery) {
      final List<SearchResultModel> geocoderResults =
          await _getGeocoderResults(query);
      for (final SearchResultModel geocoderResult in geocoderResults) {
        searchResults.add(geocoderResult);
      }
    }

    return searchResults;
  }

  Tuple2<bool, String> _getIsTourQueryAndSanitizedQuery(String query) {
    final String initialQuery = query.trim().toLowerCase();
    String sanitizedQuery = initialQuery;
    final List<String> tourQueryStartStrings = [
      'tours:',
      'tours',
      'tour:',
      'tour'
    ];

    for (final String tourQueryStartString in tourQueryStartStrings) {
      if (sanitizedQuery.startsWith(tourQueryStartString)) {
        sanitizedQuery =
            sanitizedQuery.replaceFirst(tourQueryStartString, '').trim();
      }
    }

    if (initialQuery != sanitizedQuery) {
      return Tuple2(true, sanitizedQuery);
    }
    return Tuple2(false, sanitizedQuery);
  }

  Future<List<SearchResultModel>> _getGeocoderResults(String query) async {
    // TODO replace with self hosted alternative
    final response = await http.get('https://photon.komoot.io/api/?q=$query');
    final body = json.decode(utf8.decode(response.bodyBytes));
    final features = body['features'] as List;

    return features
        .map((searchResult) => SearchResultModel.fromJson(
            searchResult as Map<String, dynamic>,
            tourListHelper: getIt()))
        .toSet()
        .toList();
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
