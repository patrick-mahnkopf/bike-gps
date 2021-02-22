import 'package:bike_gps/features/domain/entities/search/search_history_item.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

@injectable
class SearchHistoryHelper {
  // TODO implement SearchHistoryHelper

  List<SearchHistoryItem> get searchHistory => [
        SearchHistoryItem(
            name: 'testName',
            country: 'testCountry',
            coordinates: const LatLng(0, 0))
      ];
}
