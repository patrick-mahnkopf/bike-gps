import 'dart:convert';
import 'dart:io';

import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';

abstract class SearchResultLocalDataSource {
  Future<List<SearchResultModel>> getSearchHistory();
  Future<FunctionResult> addToSearchHistory(
      {@required SearchHistoryItemModel searchHistoryItemModel});
}

@Injectable(as: SearchResultLocalDataSource)
class SearchResultLocalDataSourceImpl implements SearchResultLocalDataSource {
  final ConstantsHelper constantsHelper;
  final TourListHelper tourListHelper;
  static const int searchHistoryMaxLength = 8;

  SearchResultLocalDataSourceImpl(
      {@required this.constantsHelper, @required this.tourListHelper});

  @override
  Future<List<SearchHistoryItemModel>> getSearchHistory() async {
    try {
      final List<SearchHistoryItemModel> searchHistory = [];
      final String historyContent =
          await File(constantsHelper.searchHistoryPath).readAsString();
      if (historyContent != '') {
        final List searchResults = jsonDecode(historyContent) as List;
        for (final dynamic searchResult in searchResults) {
          searchHistory.add(SearchHistoryItemModel.fromJson(
              searchResult as Map<String, dynamic>,
              tourListHelper: tourListHelper));
        }
      }
      return searchHistory;
    } on Exception {
      rethrow;
      throw FileException();
    }
  }

  @override
  Future<FunctionResult> addToSearchHistory(
      {@required SearchHistoryItemModel searchHistoryItemModel,
      @required TourListHelper tourListHelper}) async {
    try {
      List<SearchHistoryItemModel> searchHistory = await getSearchHistory();
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

  List<SearchHistoryItemModel> _removeSearchHistoryDuplicates(
      List<SearchHistoryItemModel> searchHistory) {
    return searchHistory.toSet().toList();
  }

  List<SearchHistoryItemModel> _ensureCorrectSearchHistoryLength(
      List<SearchHistoryItemModel> searchHistory) {
    if (searchHistory.length > searchHistoryMaxLength) {
      final int amountOfEntriesToRemove =
          searchHistoryMaxLength - searchHistory.length;
      return searchHistory.sublist(
          0, searchHistory.length - amountOfEntriesToRemove);
    } else {
      return searchHistory;
    }
  }
}
