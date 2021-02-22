import 'package:flutter/material.dart';

import 'features/presentation/screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dependency_injection.init();
  // await additionalDependencyInit();
  runApp(MyApp());
}

// Future<FunctionResult> additionalDependencyInit() async {
//   // TODO Change to RtxParser
//   try {
//     dependency_injection.getIt.registerLazySingleton<TourParser>(() =>
//         GpxParser(
//             constants: dependency_injection.getIt(),
//             locationHelper: dependency_injection.getIt()));
//     return FunctionResultSuccess();
//   } on Exception catch (error, stacktrace) {
//     return FunctionResultFailure(
//         error: error, stackTrace: stacktrace, name: 'additionalDependencyInit');
//   }
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike GPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) {
          return const MapScreen();
        }
      },
    );
  }
}
