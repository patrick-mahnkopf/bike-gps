import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/function_results/function_result.dart';
import 'core/helpers/constants_helper.dart';
import 'features/data/data_sources/tour_parser/tour_parser.dart';
import 'features/presentation/blocs/map/map_bloc.dart';
import 'features/presentation/blocs/simple_bloc_observer.dart';
import 'features/presentation/screens/map_screen.dart';
import 'injection_container.dart';

Future<FunctionResult> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _init();
  Bloc.observer = SimpleBlocObserver();
  runApp(MyApp());
  return FunctionResultSuccess();
}

Future<FunctionResult> _init() async {
  try {
    await configureDependencies();
    await _additionalDependencyInit();
    await getIt.allReady();
    await _systemInit();
    return FunctionResultSuccess();
  } on Exception catch (error, stacktrace) {
    return FunctionResultFailure(
        error: error, stackTrace: stacktrace, name: 'Main Init Failure');
  }
}

Future<FunctionResult> _additionalDependencyInit() async {
  try {
    getIt.registerLazySingleton<TourParser>(
        () => GpxParser(constants: getIt(), distanceHelper: getIt()));
    return FunctionResultSuccess();
  } on Exception catch (error, stacktrace) {
    return FunctionResultFailure(
        error: error,
        stackTrace: stacktrace,
        name: 'Additional dependency init failure');
  }
}

Future<FunctionResult> _systemInit() async {
  try {
    // await getIt.isReady<ConstantsHelper>();
    final ConstantsHelper constants = getIt<ConstantsHelper>();
    if (!await Directory(constants.tourDirectoryPath).exists()) {
      await Directory(constants.tourDirectoryPath).create(recursive: true);
    }
    return FunctionResultSuccess();
  } on Exception catch (error, stacktrace) {
    return FunctionResultFailure(
        error: error, stackTrace: stacktrace, name: 'System init failure');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _getMaterialApp();
  }
}

MaterialApp _getMaterialApp() {
  return MaterialApp(
      title: 'Bike GPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) {
          return BlocProvider(
            create: (context) => getIt<MapBloc>(),
            child: MapScreen(),
          );
        }
      });
}
