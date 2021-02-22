// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:http/http.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

import 'core/helpers/color_helper.dart';
import 'core/helpers/constants_helper.dart';
import 'core/helpers/distance_helper.dart';
import 'features/domain/usecases/navigation/get_navigation_data.dart';
import 'features/domain/usecases/tour/get_path_to_tour.dart';
import 'features/domain/usecases/tour/get_tour.dart';
import 'features/presentation/blocs/height_map/height_map_bloc.dart';
import 'injection_container.dart';
import 'features/presentation/blocs/map/map_bloc.dart';
import 'features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'core/controllers/mapbox_controller.dart';
import 'features/presentation/blocs/navigation/navigation_bloc.dart';
import 'features/presentation/blocs/tour/tour_bloc.dart';
import 'core/helpers/tour_conversion_helper.dart';
import 'core/helpers/helpers.dart' as bike_gps2;
import 'features/data/data_sources/tour/tour_local_data_source.dart';
import 'features/data/data_sources/tour/data_sources.dart' as bike_gps1;
import 'features/data/data_sources/tour_parser/data_sources.dart';
import 'features/data/data_sources/tour/tour_remote_data_source.dart';
import 'features/domain/repositories/tour_repository.dart';
import 'features/domain/repositories/repositories.dart' as bike_gps1;
import 'features/data/repositories/tour/tour_repository_impl.dart';

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
  gh.factory<HeightMapBloc>(() => HeightMapBloc(
      tourConversionHelper: get<bike_gps2.TourConversionHelper>()));
  final resolvedLocation = await locationModule.location;
  gh.factory<Location>(() => resolvedLocation);
  gh.factory<MapBloc>(() => MapBloc());
  gh.factory<MapboxBloc>(() => MapboxBloc());
  gh.factory<NavigationBloc>(
      () => NavigationBloc(getNavigationData: get<GetNavigationData>()));
  gh.factory<TourBloc>(
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
  gh.singleton<TourConversionHelper>(
      TourConversionHelper(constantsHelper: get<ConstantsHelper>()));
  return get;
}

class _$ClientModule extends ClientModule {}

class _$LocationModule extends LocationModule {}
