import 'package:bike_gps/search_model.dart';
import 'package:bike_gps/widgets/loading_widget.dart';
import 'package:bike_gps/widgets/map_style_list_widget.dart';
import 'package:bike_gps/widgets/mapbox_map_widget.dart';
import 'package:bike_gps/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:route_parser/route_parser.dart';

class FullMap extends StatefulWidget {
  final RouteParser routeParser;

  const FullMap(this.routeParser);

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMap> {
  bool _useMapbox = false;
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
                      child: SearchWidget(_mapboxMapStateKey),
                    ),
                  ],
                );
              }
          }
        });
  }

  changeMapStyleSource(String mapStyleName) {
    _mapboxMapStateKey.currentState.changeStyle(mapStyleName);
  }

  Future<String> _getMapboxAccessToken() async {
    if (_useMapbox) {
      return rootBundle.loadString('assets/mapbox_access_token.txt');
    } else {
      return "random_string";
    }
  }

  Future<String> _getVectorStyleString() async {
    return rootBundle.loadString('assets/vector_style_string.txt');
  }

  Future<String> _getRasterStyleString() async {
    return rootBundle.loadString('assets/raster_style_string.txt');
  }
}
