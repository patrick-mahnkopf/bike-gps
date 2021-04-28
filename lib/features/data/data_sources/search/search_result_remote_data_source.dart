import 'dart:convert';

import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_tour.dart';
import 'package:bike_gps/injection_container.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

/// Class responsible for getting search results from remote Geocoder.
abstract class SearchResultRemoteDataSource {
  Future<List<SearchResultModel>> getSearchResults({@required String query});
}

@Injectable(as: SearchResultRemoteDataSource)
class SearchResultRemoteDataSourceImpl implements SearchResultRemoteDataSource {
  final TourListHelper tourListHelper;
  final GetTour getTour;

  SearchResultRemoteDataSourceImpl(
      {@required this.tourListHelper, @required this.getTour});

  /// Retrieves search results for the given [query] from the remote Geocoder.
  ///
  /// The search results from the Geocoder describe locations. If the [query]
  /// matches one or more tour names, those tours are added to the start of
  /// the returned list.
  @override
  Future<List<SearchResultModel>> getSearchResults({String query}) async {
    final List<SearchResultModel> searchResults = [];
    final List<TourInfo> tourInfos = tourListHelper.asList;

    final Tuple2<bool, String> isTourQueryAndSanitizedQuery =
        _getIsTourQueryAndSanitizedQuery(query);
    final bool isTourQuery = isTourQueryAndSanitizedQuery.value1;
    final String sanitizedQuery = isTourQueryAndSanitizedQuery.value2;

    /// Adds tours that match the query to the search result list.
    for (final TourInfo tourInfo in tourInfos) {
      final String tourName = tourInfo.name.toLowerCase();
      if (tourName.contains(sanitizedQuery)) {
        final SearchResultModel searchResult =
            await _getSearchResultModelFromTourInfo(tourInfo);
        searchResults.add(searchResult);
      }
    }

    /// If the query doesn't start with one of the special tour shortcuts,
    /// add the Geocoder results to the search result list.
    if (!isTourQuery) {
      final List<SearchResultModel> geocoderResults =
          await _getGeocoderResults(query);
      for (final SearchResultModel geocoderResult in geocoderResults) {
        searchResults.add(geocoderResult);
      }
    }

    return searchResults;
  }

  /// Checks if [query] starts with one of the special tour shortcuts and
  /// sanitizes the [query].
  Tuple2<bool, String> _getIsTourQueryAndSanitizedQuery(String query) {
    final String initialQuery = query.trim().toLowerCase();
    String sanitizedQuery = initialQuery;
    final List<String> tourQueryStartStrings = [
      'tours:',
      'tours',
      'tour:',
      'tour'
    ];

    /// Checks if the query starts with one of the special tour search shortcuts
    /// and removes it if it does.
    for (final String tourQueryStartString in tourQueryStartStrings) {
      if (sanitizedQuery.startsWith(tourQueryStartString)) {
        sanitizedQuery =
            sanitizedQuery.replaceFirst(tourQueryStartString, '').trim();
      }
    }

    /// Returns true if a tour shortcut was used.
    if (initialQuery != sanitizedQuery) {
      return Tuple2(true, sanitizedQuery);
    }
    return Tuple2(false, sanitizedQuery);
  }

  /// Gets the Geocoder results for the [query].
  ///
  /// Removes Geocoder results that don't have a name.
  Future<List<SearchResultModel>> _getGeocoderResults(String query) async {
    // TODO replace with self hosted alternative
    final response =
        await http.get(Uri.parse('https://photon.komoot.io/api/?q=$query'));
    final body = json.decode(utf8.decode(response.bodyBytes));
    final features = body['features'] as List;

    final List<SearchResultModel> searchResultList = features
        .map((searchResult) => SearchResultModel.fromJson(
            searchResult as Map<String, dynamic>,
            tourListHelper: getIt()))
        .toSet()
        .toList();
    searchResultList.removeWhere((searchResult) => searchResult == null);
    return searchResultList;
  }

  /// Converts the [tourInfo] to a [SearchResultModel].
  ///
  /// Uses the address returned by the Geocoder to fill in the
  /// [SearchResultModel] information.
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
