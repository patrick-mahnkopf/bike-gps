import 'dart:math';

import 'package:bike_gps/place.dart';
import 'package:bike_gps/search_model.dart';
import 'package:bike_gps/widgets/mapbox_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';

class SearchWidget extends StatefulWidget {
  final GlobalKey<MapboxMapState> _mapboxMapStateKey;

  SearchWidget(this._mapboxMapStateKey);

  @override
  _SearchWidgetState createState() => _SearchWidgetState(_mapboxMapStateKey);
}

class _SearchWidgetState extends State<SearchWidget> {
  final searchBarController = FloatingSearchBarController();
  final GlobalKey<MapboxMapState> _mapboxMapStateKey;

  _SearchWidgetState(this._mapboxMapStateKey);

  int _index = 0;

  int get index => _index;

  set index(int value) {
    _index = min(value, 2);
    _index == 2 ? searchBarController.hide() : searchBarController.show();
    setState(() {});
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
              icon: const Icon(Icons.place),
              onPressed: () {},
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
    return Material(
      color: Colors.white,
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8),
      child: ImplicitlyAnimatedList<Place>(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        items: model.suggestions.take(6).toList(),
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
                    child: model.suggestions == history
                        ? const Icon(Icons.history, key: Key('history'))
                        : const Icon(Icons.place, key: Key('place')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
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

  _onSuggestionTouch(Place place) async {
    List<Address> addresses =
        await Geocoder.local.findAddressesFromQuery(place.address);
    Coordinates resultCoordinates = addresses.first.coordinates;
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(
        LatLng(resultCoordinates.latitude, resultCoordinates.longitude), 14);
    print(resultCoordinates);
    _mapboxMapStateKey.currentState.updateCameraPosition(cameraUpdate);
  }
}
