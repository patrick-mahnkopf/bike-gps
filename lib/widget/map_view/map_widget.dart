import 'package:bike_gps/model/map_resources.dart';
import 'package:bike_gps/model/search_model.dart';
import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/widget/map_view/mapbox_map_widget.dart';
import 'package:bike_gps/widget/map_view/options_dialog_widget.dart';
import 'package:bike_gps/widget/map_view/search_widget.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';

class MapWidget extends StatefulWidget {
  final RouteManager routeManager;
  final MapResources mapResources;

  const MapWidget({
    @required this.routeManager,
    @required this.mapResources,
  });

  @override
  State createState() => MapState(routeManager, mapResources);
}

class MapState extends State<MapWidget> {
  final RouteManager routeManager;
  final MapResources mapResources;
  final GlobalKey<MapboxMapState> _mapboxMapStateKey = GlobalKey();

  MapState(this.routeManager, this.mapResources);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
            resizeToAvoidBottomInset: false,
            body: MapboxMapWidget(
              key: _mapboxMapStateKey,
              routeManager: routeManager,
              mapResources: mapResources,
            )),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 64, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () => _mapboxMapStateKey.currentState
                        .showStyleSelectionDialog(),
                    child: Icon(Icons.layers),
                  ),
                ),
              ],
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchModel(),
          child: SearchWidget(
              mapboxMapStateKey: _mapboxMapStateKey,
              parent: this,
              routeManager: routeManager),
        ),
      ],
    );
  }

  openOptionsMenu() {
    showGeneralDialog(
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 100),
      context: context,
      pageBuilder: (_, __, ___) {
        return OptionsDialogWidget();
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: child,
        );
      },
    );
  }
}
