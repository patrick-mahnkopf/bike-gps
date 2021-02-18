import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../features/data/data_sources/tour/data_sources.dart';
import '../../features/data/repositories/tour/repositories.dart';
import '../../features/domain/repositories/repositories.dart';
import '../function_results/function_result.dart';

Future<FunctionResult> tourInjectionsInit(GetIt getIt) async {
  try {
    // Bloc
    getIt.registerLazySingleton<TourBloc>(
        () => TourBloc(tourRepository: getIt()));

    // Repository
    getIt.registerLazySingleton<TourRepository>(() => TourRepositoryImpl(
        localDataSource: getIt(), remoteDataSource: getIt()));

    // Data sources
    getIt.registerLazySingleton<TourLocalDataSource>(
        () => TourLocalDataSourceImpl(tourParser: getIt()));
    getIt.registerLazySingleton<TourRemoteDataSource>(
        () => TourRemoteDataSourceImpl(tourParser: getIt(), client: getIt()));
    return FunctionResultSuccess();
  } on Exception catch (error, stacktrace) {
    return FunctionResultFailure(
        error: error,
        stackTrace: stacktrace,
        name: 'GetIt initialization failed');
  }
}
