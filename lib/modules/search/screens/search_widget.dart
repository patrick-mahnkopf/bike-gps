import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bike_gps/modules/map/map.dart';
import 'package:bike_gps/modules/route_manager/route_manager.dart';
import 'package:bike_gps/modules/route_parser/route_parser.dart';
import 'package:bike_gps/modules/search/search.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route;
import 'package:geocoder/geocoder.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SearchWidget extends StatefulWidget {
  final GlobalKey<MapboxMapState> mapboxMapStateKey;
  final MapState parent;
  final RouteManager routeManager;
  final String initialQuery;

  SearchWidget({
    @required Key key,
    this.mapboxMapStateKey,
    this.parent,
    this.routeManager,
    this.initialQuery,
  }) : super(key: key);

  @override
  SearchWidgetState createState() =>
      SearchWidgetState(mapboxMapStateKey, parent, routeManager, initialQuery);
}

class SearchWidgetState extends State<SearchWidget> {
  final searchBarController = FloatingSearchBarController();
  final GlobalKey<MapboxMapState> _mapboxMapStateKey;
  final MapState parent;
  final RouteManager routeManager;
  String initialQuery;
  static const DISPLAY_SUGGESTION_COUNT = 8;
  String searchHistoryPath;

  SearchWidgetState(this._mapboxMapStateKey, this.parent, this.routeManager,
      this.initialQuery) {
    _initHistory();
  }

  int _index = 0;

  int get index => _index;

  set index(int value) {
    _index = min(value, 2);
    _index == 2 ? searchBarController.hide() : searchBarController.show();
    setState(() {});
  }

  void _initHistory() async {
    searchHistoryPath = p.join(
        (await getApplicationDocumentsDirectory()).path, 'searchHistory.json');

    if (!await File(searchHistoryPath).exists()) {
      File(searchHistoryPath).create();
    } else {
      _loadHistory();
    }
  }

  void _loadHistory() async {
    String input = await File(searchHistoryPath).readAsString();
    await routeManager.updateRouteList();
    List<String> routeNames = await routeManager.getRouteNames();

    List places = jsonDecode(input) as List;
    places.forEach((historyItem) {
      bool _isRoute = routeNames.contains(historyItem['properties']['name']);
      history.add(Place.fromJson(historyItem, isRoute: _isRoute));
    });

    _removeHistoryDuplicates();
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    if (initialQuery.isNotEmpty) searchBarController.query = initialQuery;

    return Consumer<SearchModel>(
      builder: (context, model, _) => FloatingSearchBar(
        automaticallyImplyBackButton: false,
        controller: searchBarController,
        clearQueryOnClose: false,
        hint: 'Search...',
        iconColor: Colors.grey,
        transitionDuration: const Duration(milliseconds: 800),
        transitionCurve: Curves.easeInOutCubic,
        physics: const BouncingScrollPhysics(),
        axisAlignment: isPortrait ? 0.0 : -1.0,
        openAxisAlignment: 0.0,
        maxWidth: isPortrait ? 600 : 500,
        onSubmitted: (_) => _onSubmitted(context, model),
        actions: [
          FloatingSearchBarAction(
            showIfOpened: false,
            builder: (context, _) {
              if (searchBarController.query.isEmpty) {
                return CircularButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => parent.openOptionsMenu(),
                );
              } else {
                return CircularButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _clearCurrentlyActiveSearch(),
                );
              }
            },
          ),
          FloatingSearchBarAction.searchToClear(
            showIfClosed: false,
          ),
        ],
        progress: model.isLoading,
        debounceDelay: const Duration(milliseconds: 500),
        onQueryChanged: model.onQueryChanged,
        scrollPadding: EdgeInsets.zero,
        transition: CircularFloatingSearchBarTransition(),
        builder: (context, _) => buildExpandableBody(model),
      ),
    );
  }

  _onSubmitted(BuildContext context, SearchModel model) async {
    if (searchBarController.query.isNotEmpty) {
      List<Place> suggestions = await prepareSuggestions(model);
      _onSuggestionTouch(suggestions.first);
    } else {
      _closeSearchBar();
    }
  }

  _clearCurrentlyActiveSearch() {
    searchBarController.clear();
    initialQuery = '';
    _mapboxMapStateKey.currentState.clearActiveDrawings();
  }

  Widget buildExpandableBody(SearchModel model) {
    return new FutureBuilder(
        future: prepareSuggestions(model),
        builder: (context, AsyncSnapshot<List> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Theme.of(context).platform == TargetPlatform.android
                  ? CircularProgressIndicator()
                  : CupertinoActivityIndicator();
            default:
              if (snapshot.hasError) {
                return ErrorWidget(snapshot.error);
              } else {
                List<Place> _items = snapshot.data;
                return Material(
                  color: Colors.white,
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: ImplicitlyAnimatedList<Place>(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    items: _items,
                    areItemsTheSame: (a, b) => a == b,
                    itemBuilder: (context, animation, place, i) {
                      return SizeFadeTransition(
                        animation: animation,
                        child: buildItem(context, place),
                      );
                    },
                    updateItemBuilder: (context, animation, place) {
                      return FadeTransition(
                        opacity: animation,
                        child: buildItem(context, place),
                      );
                    },
                  ),
                );
              }
          }
        });
  }

  Future<List<Place>> prepareSuggestions(SearchModel model) async {
    List<Place> suggestionList =
        model.suggestions.take(DISPLAY_SUGGESTION_COUNT).toList();

    if (!model.isHistory) {
      List<String> routeNames = await routeManager.getRouteNames();
      routeNames.retainWhere((routeName) {
        String query = searchBarController.query;
        if (query.length >= (routeName.length / 3)) {
          return routeName.toLowerCase().contains(query.toLowerCase());
        } else {
          return false;
        }
      });

      for (String routeName in routeNames) {
        Place routeSuggestion = await getPlaceFromRouteName(routeName);
        suggestionList.insert(0, routeSuggestion);
      }
    }
    return suggestionList;
  }

  Future<Place> getPlaceFromRouteName(String routeName) async {
    Route route = await routeManager.getRoute(routeName);
    Coordinates routePosition =
        Coordinates(route.trackPoints[0].lat, route.trackPoints[0].lon);
    Address address =
        (await Geocoder.local.findAddressesFromCoordinates(routePosition))
            .first;
    return Place(
      name: routeName,
      street: address.addressLine.split(',').first,
      city: address.locality,
      coordinates: LatLng(
        address.coordinates.latitude,
        address.coordinates.longitude,
      ),
      state: address.adminArea,
      country: address.countryName,
      isRoute: true,
    );
  }

  Widget buildItem(BuildContext context, Place place) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final model = Provider.of<SearchModel>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            _onSuggestionTouch(place);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: getItemIcon(model, place)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.isRoute ? "Route: ${place.name}" : place.name,
                        style: textTheme.subtitle1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.secondaryAddress,
                        style: textTheme.bodyText2
                            .copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (model.suggestions.isNotEmpty && place != model.suggestions.last)
          const Divider(height: 0),
      ],
    );
  }

  void _updateHistory(Place newPlace) {
    history.insert(0, newPlace);
    _removeHistoryDuplicates();
    while (history.length > DISPLAY_SUGGESTION_COUNT) {
      history.removeLast();
    }
    _saveHistory();
  }

  void _saveHistory() async {
    _removeHistoryDuplicates();
    File(searchHistoryPath).writeAsString(jsonEncode(history), flush: true);
  }

  void _removeHistoryDuplicates() {
    history = history.toSet().toList();
  }

  _onSuggestionTouch(Place place) {
    _closeSearchBar();
    _updateHistory(place);
    searchBarController.query = place.name;
    MapboxMapState mapState = _mapboxMapStateKey.currentState;
    mapState.clearActiveDrawings();
    if (place.isRoute) {
      mapState.onSelectRoute(place.name);
    } else {
      mapState.onSelectPlace(place);
    }
  }

  _closeSearchBar() {
    searchBarController.clear();
    searchBarController.close();
  }

  Icon getItemIcon(SearchModel model, Place place) {
    if (model.suggestions == history) {
      return Icon(Icons.history, key: Key('history'));
    } else if (place.isRoute) {
      return Icon(Icons.directions_bike, key: Key('route'));
    } else {
      return Icon(Icons.place, key: Key('place'));
    }
  }

  setActiveQuery(String routeName) {
    searchBarController.query = routeName;
  }
}
