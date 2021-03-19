import 'dart:async';
import 'dart:io';

import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/function_results/function_result.dart';
import 'core/helpers/constants_helper.dart';
import 'features/presentation/blocs/map/map_bloc.dart';
import 'features/presentation/blocs/simple_bloc_observer.dart';
import 'features/presentation/screens/map_screen.dart';
import 'injection_container.dart';

Future<FunctionResult> appStart({@required String environment}) async {
  WidgetsFlutterBinding.ensureInitialized();
  FLog.info(
      text: 'Platform: ${Platform.operatingSystem}', methodName: 'appStart');
  await _init(environment: environment);
  Bloc.observer = SimpleBlocObserver();
  runApp(const MyApp());
  return FunctionResultSuccess();
}

Future<FunctionResult> _init({@required String environment}) async {
  try {
    await configureDependencies(environment: environment);
    await getIt.allReady();
    FLog.trace(text: 'getIt allReady', methodName: '_init');
    await _systemInit();
    return FunctionResultSuccess();
  } on Exception catch (error, stacktrace) {
    FLog.error(
        text: 'Main Init Failure',
        exception: error,
        stacktrace: stacktrace,
        methodName: '_init');
    return FunctionResultFailure(
        error: error, stackTrace: stacktrace, name: 'Main Init Failure');
  }
}

Future<FunctionResult> _systemInit() async {
  try {
    FLog.trace(text: '_systemInit', methodName: '_systemInit');
    final ConstantsHelper constants = getIt<ConstantsHelper>();
    if (!await Directory(constants.tourDirectoryPath).exists()) {
      await Directory(constants.tourDirectoryPath).create(recursive: true);
      FLog.trace(
          text: 'tourDirectoryPath: ${constants.tourDirectoryPath} created');
    }
    if (!await File(constants.searchHistoryPath).exists()) {
      await File(constants.searchHistoryPath).create();
      FLog.trace(
          text: 'searchHistoryPath: ${constants.searchHistoryPath} created');
    }
    return FunctionResultSuccess();
  } on Exception catch (error, stacktrace) {
    return FunctionResultFailure(
        error: error, stackTrace: stacktrace, name: 'System init failure');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ConstantsHelper constantsHelper = getIt<ConstantsHelper>();
  StreamSubscription _intentDataStreamSubscription;
  String _sharedText;

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> values) async {
      for (final SharedMediaFile value in values) {
        final String path = value.path.replaceAll("%20", " ");
        final File file = File(path);
        FLog.trace(text: 'Flutter got file: $path while running');
        print("Got file: $path");
        await _copyFileToTourDirectory(file: file);
      }
    }, onError: (err) {
      // TODO present error dialog to User
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia()
        .then((List<SharedMediaFile> values) async {
      if (values != null) {
        for (final SharedMediaFile value in values) {
          final String path = value.path.replaceAll("%20", " ");
          final File file = File(path);
          FLog.trace(text: 'Flutter got started with file: $path');
          print("Got file: $path");
          await _copyFileToTourDirectory(file: file);
        }
      }
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      FLog.trace(text: 'Flutter got url/text: $value while running');
      setState(() {
        _sharedText = value;
      });
    }, onError: (err) {
      // TODO present error dialog to User
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      FLog.trace(text: 'Flutter got started with url/text: $value');
      setState(() {
        _sharedText = value;
      });
    });
  }

  Future<File> _copyFileToTourDirectory({@required File file}) async {
    final String baseNameWithExtension = p.basename(file.path);
    final String newPath =
        p.join(constantsHelper.tourDirectoryPath, baseNameWithExtension);
    /*
    According to the receive_sharing_intent package the received file has
    already been copied to a temp folder and will thus be moved instead of
    copied
    */
    if (Platform.isIOS) {
      FLog.trace(text: 'Handling moving incoming intent file on iOS');
      return _moveFile(
        file: file,
        newPath: newPath,
      );
    } else {
      FLog.trace(
          text: 'Handling moving incoming intent file on OS other than iOS');
      return file.copy(newPath);
    }
  }

  Future<File> _moveFile(
      {@required File file, @required String newPath}) async {
    try {
      FLog.trace(text: 'Trying to rename ${file.path} to $newPath on iOS');
      /*
      prefer using rename, thus moving the file as it is probably faster,
      but this only works in the same directory path, thus we copy instead if
      this fails
      */
      return await file.rename(newPath);
    } on FileSystemException {
      FLog.info(text: 'iOS path rename failed -> copying instead');
      // if rename fails, copy the source file and then delete it
      final newFile = await file.copy(newPath);
      await file.delete();
      return newFile;
    }
  }

  @override
  void dispose() {
    FLog.trace(text: 'Main dispose');
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _getMaterialApp();
  }
}

MaterialApp _getMaterialApp() {
  return MaterialApp(
      title: 'Bike GPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) {
          return BlocProvider(
            create: (context) => getIt<MapBloc>(),
            child: const MapScreen(),
          );
        }
      });
}
