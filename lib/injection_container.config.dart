// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// Package imports:
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

// Project imports:
import 'core/controllers/mapbox_controller.dart';
import 'core/helpers/color_helper.dart';
import 'core/helpers/constants_helper.dart';
import 'core/helpers/distance_helper.dart';
import 'core/helpers/turn_symbol_helper.dart';
import 'features/data/data_sources/tour/data_sources.dart' as bike_gps1;
import 'features/data/data_sources/tour/tour_local_data_source.dart';
import 'features/data/data_sources/tour/tour_remote_data_source.dart';
import 'features/data/data_sources/tour_parser/data_sources.dart';
import 'features/data/repositories/tour/tour_repository_impl.dart';
import 'features/domain/repositories/repositories.dart' as bike_gps1;
import 'features/domain/repositories/tour_repository.dart';
import 'features/domain/usecases/navigation/get_navigation_data.dart';
import 'features/domain/usecases/tour/get_path_to_tour.dart';
import 'features/domain/usecases/tour/get_tour.dart';
import 'features/presentation/blocs/map/map_bloc.dart';
import 'features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'features/presentation/blocs/navigation/navigation_bloc.dart';
import 'features/presentation/blocs/tour/tour_bloc.dart';
import 'injection_container.dart';

/// adds generated dependencies
/// to the provided [GetIt] instance

Future<GetIt> $initGetIt(
  GetIt get, {
  String environment,
  EnvironmentFilter environmentFilter,
}) async {
  final gh = GetItHelper(get, environment, environmentFilter);
  final clientModule = _$ClientModule();
  final locationModule = _$LocationModule();
  gh.factory<Client>(() => clientModule.get());
  gh.factory<ColorHelper>(() => ColorHelper());
  gh.factory<DistanceHelper>(() => DistanceHelper());
  gh.lazySingleton<GetNavigationData>(
      () => GetNavigationData(distanceHelper: get<DistanceHelper>()));
  gh.lazySingleton<GetPathToTour>(
      () => GetPathToTour(repository: get<bike_gps1.TourRepository>()));
  gh.lazySingleton<GetTour>(
      () => GetTour(repository: get<bike_gps1.TourRepository>()));
  final resolvedLocation = await locationModule.location;
  gh.factory<Location>(() => resolvedLocation);
  gh.lazySingleton<MapBloc>(() => MapBloc());
  gh.lazySingleton<MapboxBloc>(() => MapboxBloc());
  gh.lazySingleton<NavigationBloc>(
      () => NavigationBloc(getNavigationData: get<GetNavigationData>()));
  gh.lazySingleton<TourBloc>(
      () => TourBloc(tourRepository: get<bike_gps1.TourRepository>()));
  gh.factory<TourLocalDataSource>(
      () => TourLocalDataSourceImpl(tourParser: get<TourParser>()));
  gh.factory<TourRemoteDataSource>(() => TourRemoteDataSourceImpl(
      tourParser: get<TourParser>(), client: get<Client>()));
  gh.factory<TourRepository>(() => TourRepositoryImpl(
      localDataSource: get<bike_gps1.TourLocalDataSource>(),
      remoteDataSource: get<bike_gps1.TourRemoteDataSource>()));

  // Eager singletons must be registered in the right order
  final resolvedConstantsHelper = await ConstantsHelper.create();
  gh.singleton<ConstantsHelper>(resolvedConstantsHelper);
  gh.singletonAsync<MapboxController>(() => MapboxController.create());
  gh.singleton<TurnSymbolHelper>(
      TurnSymbolHelper(constantsHelper: get<ConstantsHelper>()));
  return get;
}

class _$ClientModule extends ClientModule {}

class _$LocationModule extends LocationModule {}
