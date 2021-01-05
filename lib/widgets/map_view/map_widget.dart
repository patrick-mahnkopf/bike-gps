import 'package:bike_gps/search_model.dart';
import 'package:bike_gps/widgets/loading_widget.dart';
import 'package:bike_gps/widgets/map_view/map_style_list_widget.dart';
import 'package:bike_gps/widgets/map_view/mapbox_map_widget.dart';
import 'package:bike_gps/widgets/map_view/options_dialog_widget.dart';
import 'package:bike_gps/widgets/map_view/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:route_parser/route_parser.dart';

class FullMapWidget extends StatefulWidget {
  final RouteParser routeParser;

  const FullMapWidget(this.routeParser);

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMapWidget> {
  bool useMapbox = false;
  String mapboxAccessToken;
  final Map styleStrings = {};
  final List<String> styleStringNames = ['Vector', 'Raster'];
  final GlobalKey<MapStyleListState> _mapStyleListStateKey = GlobalKey();
  final GlobalKey<MapboxMapState> _mapboxMapStateKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return new FutureBuilder(
        future: Future.wait([
          _getMapboxAccessToken(),
          _getVectorStyleString(),
          _getRasterStyleString()
        ]),
        builder: (context, AsyncSnapshot<List> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return LoadingWidget();
            default:
              if (snapshot.hasError) {
                return ErrorWidget(snapshot.error);
              } else {
                mapboxAccessToken = snapshot.data[0];
                styleStrings[styleStringNames[0]] = snapshot.data[1];
                styleStrings[styleStringNames[1]] = snapshot.data[2];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Scaffold(
                        resizeToAvoidBottomInset: false,
                        body: MapboxMapWidget(
                            key: _mapboxMapStateKey, parent: this)),
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
                                onPressed: () => _mapStyleListStateKey
                                    .currentState
                                    .toggleVisibility(),
                                child: Icon(Icons.layers),
                              ),
                            ),
                            MapStyleListWidget(
                              key: _mapStyleListStateKey,
                              changeStyleCallback: changeMapStyleSource,
                              styleStringNames: styleStringNames,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ChangeNotifierProvider(
                      create: (_) => SearchModel(),
                      child: SearchWidget(
                          mapboxMapStateKey: _mapboxMapStateKey, parent: this),
                    ),
                  ],
                );
              }
          }
        });
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
          // Tween(begin: Offset(0.1, -0.25), end: Offset(0, 0)).animate(anim),
          child: child,
        );
      },
    );
  }

  changeMapStyleSource(String mapStyleName) {
    _mapboxMapStateKey.currentState.changeStyle(mapStyleName);
  }

  Future<String> _getMapboxAccessToken() async {
    if (useMapbox) {
      return rootBundle.loadString('assets/map/mapbox_access_token.txt');
    } else {
      return "random_string";
    }
  }

  Future<String> _getVectorStyleString() async {
    return rootBundle.loadString('assets/map/vector_style_string.txt');
  }

  Future<String> _getRasterStyleString() async {
    return rootBundle.loadString('assets/map/raster_style_string.txt');
  }
}
