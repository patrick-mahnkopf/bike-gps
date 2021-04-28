import 'package:f_logs/f_logs.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

import 'core/function_results/function_result.dart';
import 'injection_container.config.dart';

/// The global [GetIt] instance.
final GetIt getIt = GetIt.instance;

/// Initializes the dependency injection.
@InjectableInit(
  initializerName: r'$initGetIt', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
Future<FunctionResult> configureDependencies(
    {@required String environment}) async {
  try {
    FLog.trace(
        text: 'configureDependencies', methodName: 'configureDependencies');
    await $initGetIt(getIt, environment: environment);
    return FunctionResultSuccess();
  } on Exception catch (error, stacktrace) {
    return FunctionResultFailure(
        error: error, stackTrace: stacktrace, name: 'GetIt Init Failure');
  }
}

/// Initializes the [Location] module.
///
/// Requests location permissions. Sets the minimum distance to register
/// location changes to 2 meters.
@module
abstract class LocationModule {
  @preResolve
  Future<Location> get location async {
    FLog.trace(text: 'LocationModule init');
    final Location location = Location();
    final hasPermissions = await location.hasPermission();

    /// No location permissions given. Requests permissions.
    if (hasPermissions != PermissionStatus.granted) {
      await location.requestPermission();
    }

    /// Changes the minimum position change for new locations to 2 meters.
    await location.changeSettings(distanceFilter: 2);
    return location;
  }
}

/// Initializes the http [Client].
@module
abstract class ClientModule {
  @injectable
  Client get() => Client();
}
