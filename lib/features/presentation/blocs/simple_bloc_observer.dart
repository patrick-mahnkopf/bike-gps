import 'dart:developer';

import 'package:bloc/bloc.dart';

// We can extend `BlocObserver` and override `onTransition` and `onError`
// in order to handle transitions and errors from all Blocs.
class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object event) {
    log('Event: $event', name: 'SimpleBlocObserver', time: DateTime.now());
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    log('Transition: { currentState: ${transition.currentState},\nevent: ${transition.event},\nnextState: ${transition.nextState},\n }',
        name: 'SimpleBlocObserver', time: DateTime.now());
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log(error.toString(),
        error: error,
        stackTrace: stackTrace,
        name: 'SimpleBlocObserver',
        time: DateTime.now());
    super.onError(bloc, error, stackTrace);
  }
}
