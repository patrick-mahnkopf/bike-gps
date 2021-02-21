// import 'package:flutter/services.dart';
// import 'package:get_it/get_it.dart';
// import 'package:location/location.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';

// import '../../features/presentation/blocs/mapbox/mapbox_bloc.dart';
// import '../../injection_container.dart';
// import '../controllers/mapbox_controller.dart';
// import '../function_results/function_result.dart';

// const String _mapStringsBasePath = 'assets/tokens/';
// const bool _useMapbox = false;

// Future<FunctionResult> mapboxInjectionsInit(GetIt getIt) async {
//   try {
//     // Bloc
//     getIt.registerLazySingleton<MapboxBloc>(() => MapboxBloc());

//     getIt.registerSingletonAsync<MapboxController>(
//         () => _initMapboxController());
//     return FunctionResultSuccess();
//   } on Exception catch (error, stacktrace) {
//     return FunctionResultFailure(
//         error: error,
//         stackTrace: stacktrace,
//         name: 'GetIt initialization failed');
//   }
// }

// Future<MapboxController> _initMapboxController() async {
//   final String accessToken = await _getMapboxAccessToken();
//   final Map<String, String> styleStrings = await _getStyleStrings();
//   final CameraPosition initialCameraPosition =
//       await _getInitialCameraPosition();

//   return MapboxController(
//       accessToken: accessToken,
//       styleStrings: styleStrings,
//       activeStyleString: styleStrings.values.first,
//       compassEnabled: true,
//       initialCameraPosition: initialCameraPosition,
//       locationRenderMode: MyLocationRenderMode.COMPASS,
//       myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass);
// }

// Future<String> _getMapboxAccessToken() async {
//   if (_useMapbox) {
//     return rootBundle
//         .loadString('${_mapStringsBasePath}mapbox_access_token.txt');
//   } else {
//     return 'random_string';
//   }
// }

// Future<Map<String, String>> _getStyleStrings() async {
//   return {
//     'vector': await rootBundle
//         .loadString('${_mapStringsBasePath}vector_style_string.txt'),
//     'raster': await rootBundle
//         .loadString('${_mapStringsBasePath}raster_style_string.txt')
//   };
// }

// Future<CameraPosition> _getInitialCameraPosition() async {
//   await getIt.isReady<Location>();
//   final LocationData locationData = await getIt<Location>().getLocation();
//   return CameraPosition(
//       target: LatLng(locationData.latitude, locationData.longitude), zoom: 14);
// }
