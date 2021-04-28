import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:f_logs/f_logs.dart';

/// Extends the BlocObserver to log all BLoC changes across the app.
class SimpleBlocObserver extends BlocObserver {
  /// Logs all BLoC events across the app.
  @override
  void onEvent(Bloc bloc, Object event) {
    log('Event: $event', name: 'SimpleBlocObserver', time: DateTime.now());
    FLog.info(text: 'Event: $event');
    super.onEvent(bloc, event);
  }

  /// Logs all BLoC transitions across the app.
  @override
  void onTransition(Bloc bloc, Transition transition) {
    log('Transition: { currentState: ${transition.currentState},\nevent: ${transition.event},\nnextState: ${transition.nextState},\n }',
        name: 'SimpleBlocObserver', time: DateTime.now());
    FLog.info(
        text:
            'Transition: { currentState: ${transition.currentState},\nevent: ${transition.event},\nnextState: ${transition.nextState},\n }');
    super.onTransition(bloc, transition);
  }

  /// Logs all BLoC errors across the app.
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log(error.toString(),
        error: error,
        stackTrace: stackTrace,
        name: 'SimpleBlocObserver',
        time: DateTime.now());
    FLog.error(
        text: error.toString(),
        exception: error as Exception,
        stacktrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
