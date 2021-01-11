import 'dart:io';
import 'dart:math';

import 'package:bike_gps/model/place.dart';
import 'package:bike_gps/model/search_model.dart';
import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/widget/map_view/map_widget.dart';
import 'package:bike_gps/widget/map_view/mapbox_map_widget.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route;
import 'package:geocoder/geocoder.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:route_parser/models/route.dart';

class SearchWidget extends StatefulWidget {
  final GlobalKey<MapboxMapState> mapboxMapStateKey;
  final MapState parent;
  final RouteManager routeManager;

  SearchWidget({this.mapboxMapStateKey, this.parent, this.routeManager});

  @override
  _SearchWidgetState createState() =>
      _SearchWidgetState(mapboxMapStateKey, parent, routeManager);
}

class _SearchWidgetState extends State<SearchWidget> {
  final searchBarController = FloatingSearchBarController();
  final GlobalKey<MapboxMapState> _mapboxMapStateKey;
  final MapState parent;
  final RouteManager routeManager;
  static const DISPLAY_SUGGESTION_COUNT = 8;
  String searchHistoryPath;

  _SearchWidgetState(this._mapboxMapStateKey, this.parent, this.routeManager) {
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
        (await getApplicationDocumentsDirectory()).path, 'searchHistory.txt');

    if (!await File(searchHistoryPath).exists()) {
      File(searchHistoryPath).create();
    } else {
      _loadHistory();
    }
  }

  void _loadHistory() async {
    String input = await File(searchHistoryPath).readAsString();
    List<String> routeList = await routeManager.getRouteList();

    for (String line in input.split('\n')) {
      if (line != '') {
        List<String> properties = line.split('|');
        bool _isRoute = routeList.contains(properties[0]);

        Place place = new Place(
            name: properties[0],
            country: properties[1],
            state: properties[2],
            isRoute: _isRoute);
        history.add(place);
      }
    }

    _removeHistoryDuplicates();
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Consumer<SearchModel>(
      builder: (context, model, _) => FloatingSearchBar(
        automaticallyImplyBackButton: false,
        controller: searchBarController,
        clearQueryOnClose: true,
        hint: 'Search...',
        iconColor: Colors.grey,
        transitionDuration: const Duration(milliseconds: 800),
        transitionCurve: Curves.easeInOutCubic,
        physics: const BouncingScrollPhysics(),
        axisAlignment: isPortrait ? 0.0 : -1.0,
        openAxisAlignment: 0.0,
        maxWidth: isPortrait ? 600 : 500,
        actions: [
          FloatingSearchBarAction(
            showIfOpened: false,
            child: CircularButton(
              icon: const Icon(Icons.menu),
              onPressed: () => parent.openOptionsMenu(),
            ),
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

  Widget buildExpandableBody(SearchModel model) {
    return new FutureBuilder(
        future: Future.wait([prepareSuggestions(model)]),
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
                List<Place> _items = snapshot.data.first;
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
      List<String> routeList = await routeManager.getRouteList();
      routeList.retainWhere((routeName) {
        String query = searchBarController.query;
        if (query.length >= (routeName.length / 3)) {
          return routeName.toLowerCase().contains(query.toLowerCase());
        } else {
          return false;
        }
      });

      for (String routeName in routeList) {
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
    List<Address> addresses =
        await Geocoder.local.findAddressesFromCoordinates(routePosition);
    return Place(
        name: routeName,
        state: addresses.first.adminArea,
        country: addresses.first.countryName,
        isRoute: true);
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
            _updateHistory(place);
            _onSuggestionTouch(place);
            FloatingSearchBar.of(context).close();
            Future.delayed(
              const Duration(milliseconds: 500),
              () => model.clear(),
            );
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
                        place.level2Address,
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
    String output = '';
    for (Place place in history) {
      output += "${place.name}|${place.country}|${place.state}\n";
    }
    File(searchHistoryPath).writeAsString(output, flush: true);
  }

  void _removeHistoryDuplicates() {
    history = history.toSet().toList();
  }

  _onSuggestionTouch(Place place) {
    MapboxMapState mapState = _mapboxMapStateKey.currentState;
    mapState.clearAllDrawnRoutes();
    if (place.isRoute) {
      mapState.onSelectRoute(place.name);
    } else {
      mapState.moveCameraToPlace(place);
    }
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
}
