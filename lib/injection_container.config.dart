// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:http/http.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

import 'features/domain/usecases/search/add_to_search_history.dart';
import 'core/helpers/color_helper.dart';
import 'core/helpers/constants_helper.dart';
import 'core/helpers/distance_helper.dart';
import 'features/domain/usecases/navigation/get_navigation_data.dart';
import 'features/domain/usecases/tour/get_path_to_tour.dart';
import 'features/domain/usecases/search/get_search_history.dart';
import 'features/domain/usecases/search/get_search_results.dart';
import 'features/domain/usecases/tour/get_tour.dart';
import 'features/presentation/blocs/height_map/height_map_bloc.dart';
import 'injection_container.dart';
import 'features/presentation/blocs/map/map_bloc.dart';
import 'features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'core/controllers/mapbox_controller.dart';
import 'features/presentation/blocs/navigation/navigation_bloc.dart';
import 'features/presentation/blocs/search/search_bloc.dart';
import 'features/data/data_sources/search/search_result_local_data_source.dart';
import 'features/data/data_sources/search/search_result_remote_data_source.dart';
import 'features/domain/repositories/search/search_result_repository.dart';
import 'features/data/repositories/search/search_result_repository_impl.dart';
import 'features/presentation/blocs/tour/tour_bloc.dart';
import 'core/helpers/tour_conversion_helper.dart';
import 'core/helpers/tour_list_helper.dart';
import 'features/data/data_sources/tour/tour_local_data_source.dart';
import 'features/data/data_sources/tour_parser/tour_parser.dart';
import 'features/data/data_sources/tour/tour_remote_data_source.dart';
import 'features/domain/repositories/tour/tour_repository.dart';
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
  final resolvedConstantsHelper = await ConstantsHelper.create();
  gh.factory<ConstantsHelper>(() => resolvedConstantsHelper);
  gh.factory<DistanceHelper>(() => DistanceHelper());
  gh.lazySingleton<GetNavigationData>(
      () => GetNavigationData(distanceHelper: get<DistanceHelper>()));
  final resolvedLocation = await locationModule.location;
  gh.factory<Location>(() => resolvedLocation);
  gh.factory<MapBloc>(() => MapBloc());
  gh.factory<MapboxBloc>(() => MapboxBloc());
  gh.factory<NavigationBloc>(
      () => NavigationBloc(getNavigationData: get<GetNavigationData>()));
  gh.factory<TourConversionHelper>(
      () => TourConversionHelper(constantsHelper: get<ConstantsHelper>()));
  gh.factory<TourParser>(() => GpxParser(
      constants: get<ConstantsHelper>(),
      distanceHelper: get<DistanceHelper>()));
  gh.factory<TourRemoteDataSource>(() => TourRemoteDataSourceImpl(
      tourParser: get<TourParser>(), client: get<Client>()));
  gh.factory<HeightMapBloc>(
      () => HeightMapBloc(tourConversionHelper: get<TourConversionHelper>()));
  gh.factory<TourListHelper>(() => TourListHelper(
      constantsHelper: get<ConstantsHelper>(), tourParser: get<TourParser>()));
  gh.factory<TourLocalDataSource>(() => TourLocalDataSourceImpl(
        tourParser: get<TourParser>(),
        constantsHelper: get<ConstantsHelper>(),
        tourListHelper: get<TourListHelper>(),
      ));
  gh.factory<TourRepository>(() => TourRepositoryImpl(
      localDataSource: get<TourLocalDataSource>(),
      remoteDataSource: get<TourRemoteDataSource>()));
  gh.lazySingleton<GetPathToTour>(
      () => GetPathToTour(repository: get<TourRepository>()));
  gh.lazySingleton<GetTour>(() => GetTour(repository: get<TourRepository>()));
  final resolvedSearchResultLocalDataSource =
      await SearchResultLocalDataSourceImpl.create(
          constantsHelper: get<ConstantsHelper>(),
          tourListHelper: get<TourListHelper>());
  gh.factory<SearchResultLocalDataSource>(
      () => resolvedSearchResultLocalDataSource);
  gh.factory<SearchResultRemoteDataSource>(() =>
      SearchResultRemoteDataSourceImpl(
          tourListHelper: get<TourListHelper>(), getTour: get<GetTour>()));
  gh.factory<SearchResultRepository>(() => SearchResultRepositoryImpl(
      localDataSource: get<SearchResultLocalDataSource>(),
      remoteDataSource: get<SearchResultRemoteDataSource>()));
  gh.factory<TourBloc>(() =>
      TourBloc(getTour: get<GetTour>(), getPathToTour: get<GetPathToTour>()));
  gh.lazySingleton<AddToSearchHistory>(
      () => AddToSearchHistory(repository: get<SearchResultRepository>()));
  gh.lazySingleton<GetSearchHistory>(
      () => GetSearchHistory(repository: get<SearchResultRepository>()));
  gh.lazySingleton<GetSearchResults>(
      () => GetSearchResults(repository: get<SearchResultRepository>()));
  final resolvedSearchBloc = await SearchBloc.create(
    getSearchResults: get<GetSearchResults>(),
    getSearchHistory: get<GetSearchHistory>(),
    addToSearchHistory: get<AddToSearchHistory>(),
  );
  gh.factory<SearchBloc>(() => resolvedSearchBloc);

  // Eager singletons must be registered in the right order
  gh.singletonAsync<MapboxController>(
      () => MapboxController.create(constantsHelper: get<ConstantsHelper>()));
  return get;
}

class _$ClientModule extends ClientModule {}

class _$LocationModule extends LocationModule {}
