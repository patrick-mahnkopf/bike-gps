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
import 'injection_container.dart';
import 'features/presentation/blocs/map/map_bloc.dart';
import 'features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'features/presentation/blocs/navigation/navigation_bloc.dart';
import 'features/presentation/blocs/tour/tour_bloc.dart';
import 'features/data/data_sources/tour/tour_local_data_source.dart';
import 'features/data/data_sources/tour/data_sources.dart' as bike_gps1;
import 'features/data/data_sources/tour_parser/data_sources.dart';
import 'features/data/data_sources/tour/tour_remote_data_source.dart';
import 'features/domain/repositories/tour_repository.dart';
import 'features/data/repositories/tour/tour_repository_impl.dart';
import 'core/helpers/turn_symbol_helper.dart';

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
  gh.factoryAsync<ConstantsHelper>(() => ConstantsHelper.create());
  gh.factory<DistanceHelper>(() => DistanceHelper());
  final resolvedLocation = await locationModule.location;
  gh.factory<Location>(() => resolvedLocation);
  gh.factory<MapBloc>(() => MapBloc());
  gh.factory<MapboxBloc>(() => MapboxBloc());
  gh.factory<NavigationBloc>(() => NavigationBloc(locationHelper: get()));
  gh.factory<NextWayPointsContainer>(() => NextWayPointsContainer(
        currentWayPoint: get(),
        nextWayPoint: get(),
        currentWayPointDistance: get<double>(),
      ));
  gh.factory<TourBloc>(() => TourBloc(tourRepository: get()));
  gh.factory<TourLocalDataSource>(
      () => TourLocalDataSourceImpl(tourParser: get<TourParser>()));
  gh.factory<TourRemoteDataSource>(() => TourRemoteDataSourceImpl(
      tourParser: get<TourParser>(), client: get<Client>()));
  gh.factory<TourRepository>(() => TourRepositoryImpl(
      localDataSource: get<bike_gps1.TourLocalDataSource>(),
      remoteDataSource: get<bike_gps1.TourRemoteDataSource>()));
  gh.factory<TurnSymbolHelper>(() => TurnSymbolHelper());
  return get;
}

class _$ClientModule extends ClientModule {}

class _$LocationModule extends LocationModule {}
