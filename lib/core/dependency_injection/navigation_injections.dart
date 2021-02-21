// import 'package:get_it/get_it.dart';

// import '../../features/presentation/blocs/navigation/navigation_bloc.dart';
// import '../function_results/function_result.dart';

// Future<FunctionResult> navigationInjectionsInit(GetIt getIt) async {
//   try {
//     // Bloc
//     getIt.registerLazySingleton<NavigationBloc>(
//         () => NavigationBloc(getNavigationData: getIt()));
//     return FunctionResultSuccess();
//   } on Exception catch (error, stacktrace) {
//     return FunctionResultFailure(
//         error: error,
//         stackTrace: stacktrace,
//         name: 'GetIt initialization failed');
//   }
// }
