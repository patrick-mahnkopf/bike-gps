import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapResources {
  final bool _useMapbox = true;
  String mapboxAccessToken;
  Map<String, String> styleStrings = {};

  List<String> get styleStringNames => styleStrings.keys.toList();

  String _activeStyleString;

  String get activeStyleString =>
      _useMapbox ? MapboxStyles.OUTDOORS : _activeStyleString;

  String _activeStyleStringName;

  String get activeStyleStringName => _activeStyleStringName;

  set activeStyleStringName(String newName) {
    _activeStyleStringName = newName;
    _activeStyleString = styleStrings[newName];
  }

  Future<MapResources> getMapResources() async {
    await _initMapboxAccessToken();
    await _initVectorStyleString();
    await _initRasterStyleString();
    _activeStyleString = styleStrings.values.first;
    _activeStyleStringName = styleStrings.keys.first;
    return this;
  }

  _initMapboxAccessToken() async {
    if (_useMapbox) {
      this.mapboxAccessToken =
          await rootBundle.loadString('assets/map/mapbox_access_token.txt');
    } else {
      this.mapboxAccessToken = "random_string";
    }
  }

  _initVectorStyleString() async {
    styleStrings['Vector'] =
        await rootBundle.loadString('assets/map/vector_style_string.txt');
  }

  _initRasterStyleString() async {
    styleStrings['Raster'] =
        await rootBundle.loadString('assets/map/raster_style_string.txt');
  }
}
