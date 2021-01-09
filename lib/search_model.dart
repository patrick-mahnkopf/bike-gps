import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'place.dart';

class SearchModel extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Place> _suggestions = history;

  List<Place> get suggestions => _suggestions;
  String _query = '';

  String get query => _query;
  static String searchHistoryPath;

  void onQueryChanged(String query) async {
    if (query == _query) return;

    _query = query;
    _isLoading = true;
    notifyListeners();

    if (query.isEmpty) {
      _suggestions = history;
    } else {
      final response = await http.get('http://photon.komoot.de/api/?q=$query');
      final body = json.decode(utf8.decode(response.bodyBytes));
      final features = body['features'] as List;

      _suggestions = features.map((e) => Place.fromJson(e)).toSet().toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _suggestions = history;
    notifyListeners();
  }
}

List<Place> history = [];
