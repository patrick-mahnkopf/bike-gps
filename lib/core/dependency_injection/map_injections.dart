// import 'package:get_it/get_it.dart';

// import '../../features/presentation/blocs/map/map_bloc.dart';
// import '../function_results/function_result.dart';

// Future<FunctionResult> mapInjectionsInit(GetIt getIt) async {
//   try {
//     // Bloc
//     getIt.registerLazySingleton<MapBloc>(() => MapBloc());
//     return FunctionResultSuccess();
//   } on Exception catch (error, stacktrace) {
//     return FunctionResultFailure(
//         error: error,
//         stackTrace: stacktrace,
//         name: 'GetIt initialization failed');
//   }
// }
