import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:ssh/ssh.dart';

import 'core/function_results/function_result.dart';
import 'core/helpers/constants_helper.dart';
import 'features/presentation/blocs/map/map_bloc.dart';
import 'features/presentation/blocs/simple_bloc_observer.dart';
import 'features/presentation/screens/map_screen.dart';
import 'injection_container.dart';

/// Initializes the app with the specified [environment].
///
/// This gets called by the main functions for the specific [environment].
Future<FunctionResult> appStart({@required String environment}) async {
  WidgetsFlutterBinding.ensureInitialized();
  FLog.info(
      text: 'Platform: ${Platform.operatingSystem}', methodName: 'appStart');

  /// Initializes dependency injections.
  await _init(environment: environment);

  /// Submits collected logs to the server if connected to wifi.
  await _handleLogs();

  /// Initializes the BlocObserver to monitor the app's BLoCs' states.
  Bloc.observer = SimpleBlocObserver();

  /// Starts the actual app.
  runApp(const MyApp());
  return FunctionResultSuccess();
}

/// Initializes dependency injections.
Future<FunctionResult> _init({@required String environment}) async {
  try {
    await configureDependencies(environment: environment);
    await getIt.allReady();
    FLog.trace(text: 'getIt allReady', methodName: '_init');

    /// Initializes the directories and files needed for the app.
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

/// Initializes the directories and files needed for the app.
Future<FunctionResult> _systemInit() async {
  try {
    FLog.trace(text: '_systemInit', methodName: '_systemInit');
    final ConstantsHelper constants = getIt<ConstantsHelper>();

    /// Initializes the tour directory.
    if (!await Directory(constants.tourDirectoryPath).exists()) {
      await Directory(constants.tourDirectoryPath).create(recursive: true);
      FLog.trace(
          text: 'tourDirectoryPath: ${constants.tourDirectoryPath} created');
    }

    /// Initializes the search history file.
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

/// Submits collected logs to the server if connected to wifi.
Future<FunctionResult> _handleLogs() async {
  final ConnectivityResult connectivityResult =
      await Connectivity().checkConnectivity();

  /// Only submits the logs when connected to wifi.
  if (connectivityResult == ConnectivityResult.wifi) {
    await sendLogsToServer();
  }
  return FunctionResultSuccess();
}

/// Sends the logs to the server.
Future<FunctionResult> sendLogsToServer() async {
  SSHClient client;
  try {
    /// Loads the server URL and login data.
    final List<String> logServerValues =
        (await rootBundle.loadString('assets/tokens/log_server_values.txt'))
            .split('\n');

    /// Connects to the server via SSH.
    client = SSHClient(
        host: logServerValues[0].trim(),
        port: 22,
        username: logServerValues[1].trim(),
        passwordOrKey: logServerValues[2].trim());

    FLog.info(
        text: 'Trying to connect to log server',
        methodName: 'sendLogsToServer');
    await client.connect();
    FLog.info(text: 'Connected to log server', methodName: 'sendLogsToServer');
    await client.connectSFTP();
    FLog.info(
        text: 'SFTP connected to log server', methodName: 'sendLogsToServer');
    File logFile = await FLog.exportLogs();
    logFile = await changeFileName(
        logFile, '${DateTime.now().millisecondsSinceEpoch}.txt');
    FLog.info(
        text: 'Exported FLog file to ${logFile.path}',
        methodName: 'sendLogsToServer');
    await client.sftpUpload(path: logFile.path, toPath: './logs/');
    FLog.info(
        text: 'Uploaded FLog files to log server',
        methodName: 'sendLogsToServer');
    await FLog.clearLogs();
    FLog.info(
        text: 'Platform: ${Platform.operatingSystem}',
        methodName: 'sendLogsToServer');
    FLog.info(text: 'Cleared local FLog db', methodName: 'sendLogsToServer');
    await logFile.delete();
    FLog.info(
        text: 'Deleted the local export file', methodName: 'sendLogsToServer');
  } on Exception catch (error, stackTrace) {
    return FunctionResultFailure(
        error: error, stackTrace: stackTrace, methodName: 'sendLogsToServer');
  } finally {
    client.disconnect();
  }
  return FunctionResultSuccess();
}

/// Convenience method to change the [file]'s name to [newFileName].
///
/// [newFileName] has to include the [file]'s extension.
Future<File> changeFileName(File file, String newFileName) async {
  final String path = file.path;
  final int lastSeparator = path.lastIndexOf(Platform.pathSeparator);
  final String newPath = path.substring(0, lastSeparator + 1) + newFileName;
  return file.rename(newPath);
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

    /// Handles shared files coming from outside the app while the app is still
    /// in memory.
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> values) async {
      for (final SharedMediaFile value in values) {
        final String path = value.path.replaceAll("%20", " ");
        final File file = File(path);
        FLog.trace(text: 'Flutter got file: $path while running');
        await _handleFile(file: file);
      }
    }, onError: (err) {
      // TODO present error dialog to User
    });

    /// Handles shared files coming from outside the app while the app is closed.
    ReceiveSharingIntent.getInitialMedia()
        .then((List<SharedMediaFile> values) async {
      if (values != null) {
        for (final SharedMediaFile value in values) {
          final String path = value.path.replaceAll("%20", " ");
          final File file = File(path);
          FLog.trace(text: 'Flutter got started with file: $path');
          await _handleFile(file: file);
        }
      }
    });

    /// Handles shared or opened urls/text coming from outside the app while the
    /// app is still in memory.
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      FLog.trace(text: 'Flutter got url/text: $value while running');
      setState(() {
        _sharedText = value;
      });
    }, onError: (err) {
      // TODO present error dialog to User
    });

    /// Handles shared or opened urls/text coming from outside the app while the
    /// app is closed.
    ReceiveSharingIntent.getInitialText().then((String value) {
      FLog.trace(text: 'Flutter got started with url/text: $value');
      setState(() {
        _sharedText = value;
      });
    });
  }

  /// Copies the shared [file] or it's contents for .zip files to the tour
  /// directory.
  Future<FunctionResult> _handleFile({@required File file}) async {
    try {
      final String extension = p.extension(file.path);
      if (extension == '.zip') {
        _handleZip(zipFile: file);
      } else {
        _copyFileToTourDirectory(file: file);
      }
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  /// Error handling for extracting the [zipFile].
  Future<FunctionResult> _handleZip({@required File zipFile}) async {
    try {
      FLog.trace(text: 'Handling zip file');
      await _extractZip(zipFile: zipFile);
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  /// Extracts the [zipFile] to the tour directory.
  ///
  /// Overwrites tours with the zip's contents if they already exist in the
  /// tour directory.
  Future<FunctionResult> _extractZip({@required File zipFile}) async {
    final destinationDirPath = constantsHelper.tourDirectoryPath;
    final Directory tempDirectory =
        await Directory(destinationDirPath).createTemp('.');

    /// Extracts the zip archive to a temp directory.
    await ZipFile.extractToDirectory(
        zipFile: zipFile, destinationDir: tempDirectory);

    /// Moves all files from the temp directory to the destination directory.
    for (final FileSystemEntity entity in tempDirectory.listSync()) {
      final File file = File(entity.path);
      final String fileName = p.basename(file.path);
      final String newPath = p.join(destinationDirPath, fileName);
      await _moveFile(file: file, newPath: newPath);
    }

    /// Removes the temp directory.
    await tempDirectory.delete();

    /// Deletes the zip archive in the destination directory if it was copied
    /// there by the archive library.
    final String zipFileName = p.basename(zipFile.path);
    final String zipFilePathToCheck = p.join(destinationDirPath, zipFileName);
    final File copiedZipFile = File(zipFilePathToCheck);
    if (copiedZipFile.existsSync()) {
      await copiedZipFile.delete();
    }

    return FunctionResultSuccess();
  }

  /// Copies the tour [file] to the tour directory.
  Future<File> _copyFileToTourDirectory({@required File file}) async {
    final String baseNameWithExtension = p.basename(file.path);
    final String newPath =
        p.join(constantsHelper.tourDirectoryPath, baseNameWithExtension);

    /// On iOS, tour files from the receive_sharing_intent package have already
    /// been copied to a temp directory and are thus moved instead of copied.
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

  /// Moves the [file] to [newPath].
  Future<File> _moveFile(
      {@required File file, @required String newPath}) async {
    try {
      FLog.trace(text: 'Trying to rename ${file.path} to $newPath on iOS');

      /// Prefers to rename in order to move the file as this is faster. Only
      /// works when both directories are on the same file system.
      return await file.rename(newPath);
    } on FileSystemException {
      FLog.info(text: 'iOS path rename failed -> copying instead');

      /// Copies the file if renaming the path failed.
      final newFile = await file.copy(newPath);
      await file.delete();
      return newFile;
    }
  }

  /// Disposes the app and clean up.
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

/// Builds the app's root structure.
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
    },
  );
}
