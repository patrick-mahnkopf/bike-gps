// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:get_it/get_it.dart';
// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

import 'core/helpers/helpers.dart';
import 'features/data/data_sources/tour/data_sources.dart';
import 'features/data/data_sources/tour_parser/data_sources.dart';
import 'features/data/repositories/tour/repositories.dart';
import 'features/domain/repositories/repositories.dart';
import 'features/domain/usecases/navigation/get_navigation_data.dart';
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
  gh.factoryAsync<ConstantsHelper>(() => ConstantsHelper.create());
  gh.factory<DistanceHelper>(() => DistanceHelper());
  final resolvedLocation = await locationModule.location;
  gh.factory<Location>(() => resolvedLocation);
  gh.factory<MapBloc>(() => MapBloc());
  gh.factory<MapboxBloc>(() => MapboxBloc());
  gh.factory<NavigationBloc>(
      () => NavigationBloc(getNavigationData: get<GetNavigationData>()));
  gh.factory<TourBloc>(() => TourBloc(tourRepository: get<TourRepository>()));
  gh.factory<TourLocalDataSource>(
      () => TourLocalDataSourceImpl(tourParser: get<TourParser>()));
  gh.factory<TourRemoteDataSource>(() => TourRemoteDataSourceImpl(
      tourParser: get<TourParser>(), client: get<Client>()));
  gh.factory<TourRepository>(() => TourRepositoryImpl(
      localDataSource: get<TourLocalDataSource>(),
      remoteDataSource: get<TourRemoteDataSource>()));
  gh.factory<TurnSymbolHelper>(
      () => TurnSymbolHelper(turnSymbolAssetPaths: get<Map<String, String>>()));
  return get;
}

class _$ClientModule extends ClientModule {}

class _$LocationModule extends LocationModule {}
