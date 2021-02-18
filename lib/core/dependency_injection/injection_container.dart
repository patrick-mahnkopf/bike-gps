// import 'package:bike_gps/core/dependency_injection/dependency_injections.dart';
// import 'package:bike_gps/core/function_results/function_result.dart';
// import 'package:bike_gps/core/helpers/helpers.dart';
// import 'package:get_it/get_it.dart';
// import 'package:http/http.dart';
// import 'package:injectable/injectable.dart';
// import 'package:location/location.dart';
// import 'package:path_provider/path_provider.dart';

// import 'injection_container.config.dart';

// final GetIt getIt = GetIt.instance;

// @InjectableInit(
//   initializerName: r'$initGetIt', // default
//   preferRelativeImports: true, // default
//   asExtension: false, // default
// )
// Future<FunctionResult> configureDependencies() async {
//   try {
//     await $initGetIt(getIt);
//     return FunctionResultSuccess();
//   } on Exception catch (error, stacktrace) {
//     return FunctionResultFailure(
//         error: error, stackTrace: stacktrace, name: 'GetIt Init Failure');
//   }
// }

// Future<FunctionResult> init() async {
//   try {
//     // Features - Map
//     await mapInjectionsInit(getIt);

//     // Features - Mapbox
//     await mapboxInjectionsInit(getIt);

//     // Features - Navigation
//     await navigationInjectionsInit(getIt);

//     // Features - Tour
//     await tourInjectionsInit(getIt);

//     //! Core
//     getIt.registerLazySingletonAsync<ConstantsHelper>(() => initConstants());
//     getIt.registerLazySingleton<DistanceHelper>(() => DistanceHelper());
//     getIt.registerLazySingleton<TurnSymbolHelper>(() => TurnSymbolHelper());
//     getIt.registerLazySingleton<ColorHelper>(() => ColorHelper());

//     //! External
//     getIt.registerSingletonAsync<Location>(() => initLocationHandler());
//     getIt.registerLazySingleton<Client>(() => Client());

//     return FunctionResultSuccess();
//   } on Exception catch (error, stacktrace) {
//     return FunctionResultFailure(
//         error: error,
//         stackTrace: stacktrace,
//         name: 'GetIt initialization failed');
//   }
// }

// Future<Location> initLocationHandler() async {
//   final Location location = Location();
//   final hasPermissions = await location.hasPermission();
//   if (hasPermissions != PermissionStatus.granted) {
//     await location.requestPermission();
//   }
//   await location.changeSettings(distanceFilter: 5);
//   return location;
// }

// Future<ConstantsHelper> initConstants() async {
//   return ConstantsHelper(
//       applicationDocumentsDirectoryPath:
//           (await getApplicationDocumentsDirectory()).path);
// }
