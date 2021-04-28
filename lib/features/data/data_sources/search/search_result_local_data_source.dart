import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';

/// Class responsible for handling the local search history.
abstract class SearchResultLocalDataSource {
  Future<List<SearchResultModel>> getSearchHistory();
  Future<FunctionResult> addToSearchHistory(
      {@required SearchHistoryItemModel searchHistoryItemModel});
}

@preResolve
@Injectable(as: SearchResultLocalDataSource)
class SearchResultLocalDataSourceImpl implements SearchResultLocalDataSource {
  final ConstantsHelper constantsHelper;
  final TourListHelper tourListHelper;
  static const int searchHistoryMaxLength = 8;

  SearchResultLocalDataSourceImpl(
      {@required this.constantsHelper, @required this.tourListHelper});

  @factoryMethod
  static Future<SearchResultLocalDataSourceImpl> create(
      {@required ConstantsHelper constantsHelper,
      @required TourListHelper tourListHelper}) async {
    await tourListHelper.initializeTourList();
    return SearchResultLocalDataSourceImpl(
        constantsHelper: constantsHelper, tourListHelper: tourListHelper);
  }

  /// Returns a List of the most recently submitted search queries.
  ///
  /// Throws a [FileException] if the search history file could not be read.
  @override
  Future<List<SearchHistoryItemModel>> getSearchHistory() async {
    try {
      final List<SearchHistoryItemModel> searchHistory = [];
      final String historyContent =
          await File(constantsHelper.searchHistoryPath).readAsString();
      if (historyContent != '') {
        final List searchResults = jsonDecode(historyContent) as List;
        for (final dynamic searchResult in searchResults) {
          searchHistory.add(
            SearchHistoryItemModel.fromJson(
                searchResult as Map<String, dynamic>,
                tourListHelper: tourListHelper),
          );
        }
      }
      return searchHistory;
    } on Exception {
      throw FileException();
    }
  }

  /// Adds the [searchHistoryItemModel] to the search history.
  ///
  /// Adds the [searchHistoryItemModel] to the first position of the search
  /// history and writes the history to the local file. Returns a
  /// [FunctionResultFailure] if an exception occurs and a
  /// [FunctionResultSuccess] otherwise.
  @override
  Future<FunctionResult> addToSearchHistory(
      {@required SearchHistoryItemModel searchHistoryItemModel,
      @required TourListHelper tourListHelper}) async {
    try {
      List<SearchHistoryItemModel> searchHistory = await getSearchHistory();

      /// Inserts at the first position if a search history already exists
      if (searchHistory != null) {
        searchHistory.insert(0, searchHistoryItemModel);
        searchHistory = _removeSearchHistoryDuplicates(searchHistory);
        searchHistory = _ensureCorrectSearchHistoryLength(searchHistory);
      } else {
        searchHistory = [searchHistoryItemModel];
      }

      File(constantsHelper.searchHistoryPath)
          .writeAsStringSync(jsonEncode(searchHistory), flush: true);
      return FunctionResultSuccess();
    } on Exception catch (e, stacktrace) {
      return FunctionResultFailure(
          error: e,
          stackTrace: stacktrace,
          name: 'SearchResultLocalDataSource addToSearchHistory');
    }
  }

  /// Returns the search history after removing duplicate entries.
  List<SearchHistoryItemModel> _removeSearchHistoryDuplicates(
      List<SearchHistoryItemModel> searchHistory) {
    return searchHistory.toSet().toList();
  }

  // Uses LIFO order to shorten the search history if it's longer than
  // [searchHistoryMaxLengh].
  List<SearchHistoryItemModel> _ensureCorrectSearchHistoryLength(
      List<SearchHistoryItemModel> searchHistory) {
    if (searchHistory.length > searchHistoryMaxLength) {
      final int amountOfEntriesToRemove =
          max(0, searchHistory.length - searchHistoryMaxLength);
      return searchHistory.sublist(
          0, searchHistory.length - 1 - amountOfEntriesToRemove);
    } else {
      return searchHistory;
    }
  }
}
