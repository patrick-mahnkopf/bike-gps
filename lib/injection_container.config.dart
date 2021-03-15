// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:get_it/get_it.dart' as _i1;
import 'package:http/http.dart' as _i3;
import 'package:injectable/injectable.dart' as _i2;
import 'package:location/location.dart' as _i9;

import 'core/controllers/mapbox_controller.dart' as _i32;
import 'core/helpers/color_helper.dart' as _i4;
import 'core/helpers/constants_helper.dart' as _i5;
import 'core/helpers/distance_helper.dart' as _i6;
import 'core/helpers/tour_conversion_helper.dart' as _i12;
import 'core/helpers/tour_list_helper.dart' as _i15;
import 'features/data/data_sources/search/search_result_local_data_source.dart'
    as _i23;
import 'features/data/data_sources/search/search_result_remote_data_source.dart'
    as _i24;
import 'features/data/data_sources/tour/tour_local_data_source.dart' as _i16;
import 'features/data/data_sources/tour/tour_remote_data_source.dart' as _i13;
import 'features/data/data_sources/tour_parser/rtx_parser.dart' as _i34;
import 'features/data/data_sources/tour_parser/tour_parser.dart' as _i8;
import 'features/data/repositories/search/search_result_repository_impl.dart'
    as _i26;
import 'features/data/repositories/tour/tour_repository_impl.dart' as _i18;
import 'features/domain/repositories/search/search_result_repository.dart'
    as _i25;
import 'features/domain/repositories/tour/tour_repository.dart' as _i17;
import 'features/domain/usecases/navigation/get_navigation_data.dart' as _i7;
import 'features/domain/usecases/search/add_to_search_history.dart' as _i28;
import 'features/domain/usecases/search/get_search_history.dart' as _i29;
import 'features/domain/usecases/search/get_search_results.dart' as _i30;
import 'features/domain/usecases/tour/get_alternative_tours.dart' as _i19;
import 'features/domain/usecases/tour/get_path_to_tour.dart' as _i20;
import 'features/domain/usecases/tour/get_tour.dart' as _i21;
import 'features/presentation/blocs/height_map/height_map_bloc.dart' as _i14;
import 'features/presentation/blocs/map/map_bloc.dart' as _i10;
import 'features/presentation/blocs/mapbox/mapbox_bloc.dart' as _i11;
import 'features/presentation/blocs/navigation/navigation_bloc.dart' as _i22;
import 'features/presentation/blocs/search/search_bloc.dart' as _i31;
import 'features/presentation/blocs/tour/tour_bloc.dart' as _i27;
import 'injection_container.dart' as _i33;

const String _rtx = 'rtx';
const String _public = 'public';
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: lines_longer_than_80_chars
/// initializes the registration of provided dependencies inside of [GetIt]
Future<_i1.GetIt> $initGetIt(_i1.GetIt get,
    {String environment, _i2.EnvironmentFilter environmentFilter}) async {
  final gh = _i2.GetItHelper(get, environment, environmentFilter);
  final clientModule = _$ClientModule();
  final gpxParserModule = _$GpxParserModule();
  final locationModule = _$LocationModule();
  final rtxParserModule = _$RtxParserModule();
  gh.factory<_i3.Client>(() => clientModule.get());
  gh.factory<_i4.ColorHelper>(() => _i4.ColorHelper());
  await gh.factoryAsync<_i5.ConstantsHelper>(() => _i5.ConstantsHelper.create(),
      preResolve: true);
  gh.factory<_i6.DistanceHelper>(() => _i6.DistanceHelper());
  gh.lazySingleton<_i7.GetNavigationData>(
      () => _i7.GetNavigationData(distanceHelper: get<_i6.DistanceHelper>()));
  gh.factory<_i8.GpxParser>(
      () => gpxParserModule.getGpxParser(
          get<_i5.ConstantsHelper>(), get<_i6.DistanceHelper>()),
      registerFor: {_rtx});
  await gh.factoryAsync<_i9.Location>(() => locationModule.location,
      preResolve: true);
  gh.factory<_i10.MapBloc>(() => _i10.MapBloc());
  gh.factory<_i11.MapboxBloc>(() => _i11.MapboxBloc());
  gh.factory<_i12.TourConversionHelper>(() =>
      _i12.TourConversionHelper(constantsHelper: get<_i5.ConstantsHelper>()));
  gh.factory<_i8.TourParser>(
      () => rtxParserModule.getRtxParser(get<_i5.ConstantsHelper>(),
          get<_i6.DistanceHelper>(), get<_i8.GpxParser>()),
      registerFor: {_rtx});
  gh.factory<_i8.TourParser>(
      () => _i8.GpxParser(
          constantsHelper: get<_i5.ConstantsHelper>(),
          distanceHelper: get<_i6.DistanceHelper>()),
      registerFor: {_public});
  gh.factory<_i13.TourRemoteDataSource>(() => _i13.TourRemoteDataSourceImpl(
      tourParser: get<_i8.TourParser>(),
      client: get<_i3.Client>(),
      constantsHelper: get<_i5.ConstantsHelper>()));
  gh.lazySingleton<_i14.HeightMapBloc>(() => _i14.HeightMapBloc(
      tourConversionHelper: get<_i12.TourConversionHelper>()));
  gh.lazySingleton<_i15.TourListHelper>(() => _i15.TourListHelper(
      constantsHelper: get<_i5.ConstantsHelper>(),
      tourParser: get<_i8.TourParser>()));
  gh.factory<_i16.TourLocalDataSource>(() => _i16.TourLocalDataSourceImpl(
      tourParser: get<_i8.TourParser>(),
      constantsHelper: get<_i5.ConstantsHelper>(),
      tourListHelper: get<_i15.TourListHelper>()));
  gh.factory<_i17.TourRepository>(() => _i18.TourRepositoryImpl(
      localDataSource: get<_i16.TourLocalDataSource>(),
      remoteDataSource: get<_i13.TourRemoteDataSource>()));
  gh.lazySingleton<_i19.GetAlternativeTours>(
      () => _i19.GetAlternativeTours(repository: get<_i17.TourRepository>()));
  gh.lazySingleton<_i20.GetPathToTour>(
      () => _i20.GetPathToTour(repository: get<_i17.TourRepository>()));
  gh.lazySingleton<_i21.GetTour>(
      () => _i21.GetTour(repository: get<_i17.TourRepository>()));
  gh.factory<_i22.NavigationBloc>(() => _i22.NavigationBloc(
      getNavigationData: get<_i7.GetNavigationData>(),
      getPathToTour: get<_i20.GetPathToTour>(),
      distanceHelper: get<_i6.DistanceHelper>()));
  await gh.factoryAsync<_i23.SearchResultLocalDataSource>(
      () => _i23.SearchResultLocalDataSourceImpl.create(
          constantsHelper: get<_i5.ConstantsHelper>(),
          tourListHelper: get<_i15.TourListHelper>()),
      preResolve: true);
  gh.factory<_i24.SearchResultRemoteDataSource>(() =>
      _i24.SearchResultRemoteDataSourceImpl(
          tourListHelper: get<_i15.TourListHelper>(),
          getTour: get<_i21.GetTour>()));
  gh.factory<_i25.SearchResultRepository>(() => _i26.SearchResultRepositoryImpl(
      localDataSource: get<_i23.SearchResultLocalDataSource>(),
      remoteDataSource: get<_i24.SearchResultRemoteDataSource>()));
  gh.lazySingleton<_i27.TourBloc>(() => _i27.TourBloc(
      getTour: get<_i21.GetTour>(),
      getAlternativeTours: get<_i19.GetAlternativeTours>()));
  gh.lazySingleton<_i28.AddToSearchHistory>(() =>
      _i28.AddToSearchHistory(repository: get<_i25.SearchResultRepository>()));
  gh.lazySingleton<_i29.GetSearchHistory>(() =>
      _i29.GetSearchHistory(repository: get<_i25.SearchResultRepository>()));
  gh.lazySingleton<_i30.GetSearchResults>(() =>
      _i30.GetSearchResults(repository: get<_i25.SearchResultRepository>()));
  await gh.factoryAsync<_i31.SearchBloc>(
      () => _i31.SearchBloc.create(
          getSearchResults: get<_i30.GetSearchResults>(),
          getSearchHistory: get<_i29.GetSearchHistory>(),
          addToSearchHistory: get<_i28.AddToSearchHistory>()),
      preResolve: true);
  gh.singletonAsync<_i32.MapboxController>(() => _i32.MapboxController.create(
      constantsHelper: get<_i5.ConstantsHelper>(),
      tourListHelper: get<_i15.TourListHelper>(),
      searchBloc: get<_i31.SearchBloc>(),
      tourBloc: get<_i27.TourBloc>()));
  return get;
}

class _$ClientModule extends _i33.ClientModule {}

class _$GpxParserModule extends _i34.GpxParserModule {}

class _$LocationModule extends _i33.LocationModule {}

class _$RtxParserModule extends _i34.RtxParserModule {}
